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
            print("[MultimediaPlayer - PiPVideoPlayer.makeUIViewController]: Cannot set audio session to playback movies & active: \(error)")
        }
        
//        playerController.updatesNowPlayingInfoCenter = false
        // The default for this is true, so that the player controller will set the info center properties
        // We want the player VC's player to manage the info center
        
        // We do however want to add the metadata to the player's currentItem, so the static details appear in the info center
        if let item = player.currentItem {
            NowPlayingHelper.publishMetadata(metadata, to: item)
        } else {
            print("[MultimediaPlayer - PiPVideoPlayer: Cannot get the player's current AVPlayerItem to set its metadata")
        }
        
        return playerController
    }
    
    // Remember: Called when the CALLEE swiftUI view updates the state that this view depends on
    public func updateUIViewController(_ playerViewController: AVPlayerViewController, context: Context) {
    }
    
    
    // MARK: - Coordinator
    
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
            print("[MultimediaPlayer - PiPVieoPlayer.playerViewControllerFailedToStartPictureInPictureWithError]: Error = \(error)")
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
