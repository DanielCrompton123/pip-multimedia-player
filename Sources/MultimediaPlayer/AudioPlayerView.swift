//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 26/03/2026.
//

import SwiftUI

public struct AudioPlayerView: View {
    private let player: AudioPlayer
    private let metadata: NowPlayingMetadata
        
    public init(
        player: AudioPlayer,
        metadata: NowPlayingMetadata = .init()
    ) {
        self.player = player
        self.metadata = metadata
    }
    
    public var body: some View {
        GeometryReader { geom in
            
            HStack {
                Button(action: player.backtrack) {
                    Label("Backtrack", systemImage: "\(player.backtrackSkipInterval.string).arrow.trianglehead.counterclockwise")
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
                    Label("Skip", systemImage: "\(player.backtrackSkipInterval.string).arrow.trianglehead.clockwise")
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
                Image(uiImage: metadata.thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geom.size.width, height: geom.size.height)
                    .clipped()
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

