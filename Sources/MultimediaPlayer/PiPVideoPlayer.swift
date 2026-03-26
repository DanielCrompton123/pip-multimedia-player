//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 24/03/2026.
//

import SwiftUI
import AVKit


public enum PiPVideoPlayerPresentation: Sendable {
    /// State is PiP when the player view controller is in PiP mode
    case pip
    /// State is full-screen when the user presses the full-screen button in the player view controller & the player goes into a full screen overlay type presentation
    case fullScreen
    /// State is inline normally when the app is open and PiP is not used, and when the player is not made full-screen
    case inline
    
    /// the default state resolving to inline
    static public let `default` = Self.inline
}


/*
@MainActor
class PiPVideoPlayerEventObserving: NSObject {
    let player: AVPlayer
    
    init(player: AVPlayer) {
        self.player = player
    }
    
    private var observers: [NSKeyValueObservation] = []
    
    func startEventObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(playedToEnd), name: AVPlayerItem.didPlayToEndTimeNotification, object: nil)
    }
    
    
    @objc private func playedToEnd() {
        // Called when the notification triggers saying that the player has played to the end
    }
    
}
*/



public struct PiPVideoPlayer: UIViewControllerRepresentable {
    
    private let player: AVPlayer
    @Binding private var playerPresentationState: PiPVideoPlayerPresentation
    private let metadata: NowPlayingMetadata
    
    public init(
        player: AVPlayer,
        playerPresentationState: Binding<PiPVideoPlayerPresentation>,
        metadata: NowPlayingMetadata = .init()
    ) {
        self.player = player
        self._playerPresentationState = playerPresentationState
        self.metadata = metadata
    }
    
    private let playerController = AVPlayerViewController()
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        // Set up the view controller to begin with
        playerController.player = player
        playerController.allowsPictureInPicturePlayback = true
        playerController.canStartPictureInPictureAutomaticallyFromInline = true
        playerController.delegate = context.coordinator
        
        // Set up the category for the audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[PiPVideoPlayer.makeUIViewController]: Cannot set audio session to playback movies & active: \(error)")
        }
        
        // Set up the now playing metadata
        // Make sure this is set to false so that the player controller doesn't do anything funky with the now playing centre
        playerController.updatesNowPlayingInfoCenter = false
        NowPlayingHelper.addCommands(for: player)
        NowPlayingHelper.updateNowPlayingData(metadata)
        NowPlayingHelper.updateNowPlayingData(
            NowPlayingDynamicData(
                playbackDuration: player.currentItem?.duration.seconds ?? 0.0,
                elapsedTime: player.currentTime().seconds,
                playbackRate: player.rate
            )
        )
        
        return playerController
    }
    
    // Remember: Called when the CALLEE swiftUI view updates the state that this view depends on
    public func updateUIViewController(_ playerViewController: AVPlayerViewController, context: Context) {
    }
    
    
    // MARK: Coordinator
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(playerPresentationState: $playerPresentationState)
    }
    
    
    // The coordinator can be accessed from any thread but the presentation state can only be accessed from the main actor.
    // Therefore the delegate methods for AVPlayerViewControllerDelegate must also be isolated on the main actor
    public class Coordinator: NSObject, @MainActor AVPlayerViewControllerDelegate {
        
        @MainActor @Binding private var playerPresentationState: PiPVideoPlayerPresentation
                
        init(playerPresentationState: Binding<PiPVideoPlayerPresentation>) {
            self._playerPresentationState = playerPresentationState
        }
        
        // Full-screen
        
        @MainActor public func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
        ) {
            coordinator.animate(alongsideTransition: nil) { _ in
                self.playerPresentationState = .fullScreen
            }
        }
        
        @MainActor public func playerViewController(
            _ playerViewController: AVPlayerViewController,
            willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
        ) {
            
            // when the app is closed and PiP begins, pipWillEnter and pipDidEnter both call before the full screen closes (this calls)
            // To avoid setting the state to inline when PiP enters (and the full screen ends) make sure we are not already in PiP mode
            if playerPresentationState == .pip { return }
            
            coordinator.animate(alongsideTransition: nil) { transitionContext in
                self.playerPresentationState = .inline
                
                // Automatically, it will pause
                // Keep it playing!
                playerViewController.player?.play()
            }
        }
        
        
        // PiP
        
        public func playerViewController(
            _ playerViewController: AVPlayerViewController,
            failedToStartPictureInPictureWithError error: any Error
        ) {
            print("[PiPVieoPlayer.playerViewControllerFailedToStartPictureInPictureWithError]: Error = \(error)")
        }
        @MainActor public func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        }
        @MainActor public func playerViewControllerDidStartPictureInPicture(
            _ playerViewController: AVPlayerViewController
        ) {
            playerPresentationState = .pip
        }
        
        // END PIP
        @MainActor public func playerViewControllerDidStopPictureInPicture(
            _ playerViewController: AVPlayerViewController
        ) {
            // Always resets to inline after PiP mode ended
            playerPresentationState = .inline
        }
    }
}
 


