//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 25/03/2026.
//

import SwiftUI
import AVFoundation


/// Model wrapping the AVFoundation `AVAudioPlayer` that publishes changes to the UI when state changes like the audio is played, paused, and when `currentTime` progresses
@Observable @MainActor final public class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    // MARK: Private properties & init
    
    private let underlyingPlayer: AVAudioPlayer
    
    /// Timer that triggers at a specific interval to update the `currentTime` variable
    private var timer: Timer?
    
    public init(url: URL) throws {
        self.underlyingPlayer = try AVAudioPlayer(contentsOf: url)
    }
    
    // MARK: Play, pause, stop
    
    /// Play the audio by calling the play prepateToPlay & method of the underlying player. If the `time` parameter is used, the underlying player's `play(atTime:)` method is used to start playing at a specific time
    public func play(atTime time: TimeInterval? = nil) {
        underlyingPlayer.prepareToPlay()
        if let time {
            underlyingPlayer.play(atTime: time)
        } else {
            underlyingPlayer.play()
        }
        playbackState = .playing
        
        // Start the timer to update currentTime every time it triggers
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { timer in
            self.currentTime = self.underlyingPlayer.currentTime
        })
    }
    
    /// Calls the underlying player's `pause` method
    public func pause() {
        underlyingPlayer.pause()
        playbackState = .paused
        cancelTimer()
    }
    
    /// Toggles between play & pause mode
    public func togglePlayPause() {
        switch playbackState {
            case .stopped: play()
            case .playing: pause()
            case .paused:  play()
        }
    }
    
    /// Calls the underlying player's `stop` method
    public func stop() {
        underlyingPlayer.stop()
        playbackState = .stopped
        cancelTimer()
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: State attributes
    
    /// enum representing different states for the playback:
    public enum PlaybackState {
        case stopped, playing, paused
    }
    public private(set) var playbackState = PlaybackState.stopped
    public var isPlaying: Bool { playbackState == .playing }
    public var isPaused: Bool { playbackState == .paused }
    
    public var numberOfLoop: Int {
        get { underlyingPlayer.numberOfLoops }
        set { underlyingPlayer.numberOfLoops = newValue }
    }
    
    public var rate: Float {
        get { underlyingPlayer.rate }
        set { underlyingPlayer.rate = newValue }
    }
    
    public var enableRate: Bool {
        get { underlyingPlayer.enableRate }
        set { underlyingPlayer.enableRate = newValue }
    }
    
    // MARK: Current time updating
    
    /// Complete an action while persisting the playback state. Keep track of the playback state before the action is called and if it's `.playing`, pause before doing the action. After the action is finished, check if the original state was `playing` and if so, play the player again.
    private func persistingPlaybackState(action: () -> ()) {
        let originalState = playbackState
        if originalState == .playing { underlyingPlayer.pause() }
        action()
        if originalState == .playing { underlyingPlayer.play() }
    }
    
    /// The time interval that has been played for the audio player
    /// - Updated by the timer to keep it in sync with the player.currentTime ever n seconds
    /// - Updated when seeking to a new currentTime along with the player.currentTime
    public private(set) var currentTime: TimeInterval = 0
    
    /// Seek to a new current time
    public func seek(to time: TimeInterval) {
        persistingPlaybackState {
            // Set the current time property here and on the player
            currentTime = time
            underlyingPlayer.currentTime = time
        }
    }
    
    public var duration: TimeInterval { underlyingPlayer.duration }
    
    // MARK: Backtracking & skipping
    
    // Number of seconds to backtrack or skip when the respective methods are called
    public var backtrackSkipInterval: TimeInterval = 15.0
    
    
    /// Method to backtrack a certain number of seconds
    public func backtrack() {
        persistingPlaybackState {
            seek(to: currentTime - backtrackSkipInterval)
        }
    }
    
    /// Method to skip a certain number of seconds
    public func skip() {
        seek(to: currentTime + backtrackSkipInterval)
    }
}


public struct AudioPlayerView: View {
    private let player: AudioPlayer
    private let metadata: MultimediaMetadata
    
    @State private var isSeeking = false
    
    public init(
        player: AudioPlayer,
        metadata: MultimediaMetadata = .init()
    ) {
        self.player = player
        self.metadata = metadata
    }
    
    public var body: some View {
        GeometryReader { geom in
            
            HStack {
                Button(action: player.backtrack) {
                    Label("Backtrack", systemImage: "15.arrow.trianglehead.counterclockwise")
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity)
                
                Button(action: player.togglePlayPause) {
                    let title = player.isPlaying ? "Pause" : "Play"
                    let icon = player.isPlaying ? "pause.fill" : "play.fill"
                    Label(title, systemImage: icon)
                        .padding(10)
                        .font(.system(size: 30))
                        .bold()
                }
                .frame(maxWidth: .infinity)
                
                Button(action: player.skip) {
                    Label("Skip", systemImage: "15.arrow.trianglehead.clockwise")
                        .font(.system(size: 20))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonBorderShape(.circle)
            .labelStyle(.iconOnly)
            .frame(maxHeight: .infinity)
            .buttonStyle(.glass)
            
            .overlay(alignment: .bottom) {
                Slider(value: Binding(
                    get: { player.currentTime },
                    set: { player.seek(to: $0) }
                ), in: 0.0...player.duration) {
                } minimumValueLabel: {
                    AnyView(Text(formatTimeInterval(player.currentTime))
                        .contentTransition(.numericText(countsDown: true)))
                } maximumValueLabel: {
                    AnyView(Text(formatTimeInterval(player.duration)))
                }
                .animation(.default, value: player.currentTime)
                .padding()
            }
            
            
            .background {
                if let image = metadata.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geom.size.width, height: geom.size.height)
                        .clipped()
                }
            }
            
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        // Initialize a format that uses hours if the time interval is in hours, otherwise minutes and seconds
        let format: Duration.TimeFormatStyle
        if interval > 60 * 60 {
            format = .init(pattern: .hourMinuteSecond(padHourToLength: 2))
        } else {
            format = .init(pattern: .minuteSecond(padMinuteToLength: 2))
        }
        
        return Duration.seconds(interval).formatted(format)
    }
}
