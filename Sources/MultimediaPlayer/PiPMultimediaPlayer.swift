//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 24/03/2026.
//

import SwiftUI
import AVKit


public enum MultimediaPlayerPresentation: Sendable {
    /// State is PiP when the player view controller is in PiP mode
    case pip
    /// State is full-screen when the user presses the full-screen button in the player view controller & the player goes into a full screen overlay type presentation
    case fullScreen
    /// State is inline normally when the app is open and PiP is not used, and when the player is not made full-screen
    case inline
    
    /// the default state resolving to inline
    static public let `default` = Self.inline
}


public enum MultimediaType: Sendable {
    case video, audio
}


public struct PiPMultimediaPlayer: UIViewControllerRepresentable {
    
    private let player: AVPlayer
    private let multimediaType: MultimediaType
    @Binding private var playerPresentationState: MultimediaPlayerPresentation
    private let metadata: NowPlayingMetadata
    
    public init(
        player: AVPlayer,
        multimediaType: MultimediaType,
        playerPresentationState: Binding<MultimediaPlayerPresentation>,
        metadata: NowPlayingMetadata = .init()
    ) {
        self.player = player
        self.multimediaType = multimediaType
        self._playerPresentationState = playerPresentationState
        self.metadata = metadata
    }
    
    private let playerController = AVPlayerViewController()
    
    public func makeUIViewController(context: Context) -> AVPlayerViewController {
        // Set up the view controller to begin with
        playerController.player = player
        // Only allow PiP for videos
        playerController.allowsPictureInPicturePlayback = multimediaType == .video
        playerController.canStartPictureInPictureAutomaticallyFromInline = true
        playerController.delegate = context.coordinator
        
        // Set up the category for the audio session
        do {
            switch multimediaType {
                case .video:
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
                case .audio:
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            }
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
        
        // If the multimedia type is audio, there will be no video information showing in the view controller, so we can add the thumbnail for something to display in its original ratio
        if multimediaType == .audio {
            addThumbnailLayer()
        }
        
        return playerController
    }
    
    // Remember: Called when the CALLEE swiftUI view updates the state that this view depends on
    public func updateUIViewController(_ playerViewController: AVPlayerViewController, context: Context) {
    }
    
    
    /// Called to add the thumbnail layer into the player view controller to cover up the blackness when it's only audio playing
    private func addThumbnailLayer() {
        // Create an image view
        let imageView = UIImageView(image: metadata.thumbnail)
        // Set the scale mode so it fills up the entire view controller
        imageView.contentMode = .scaleAspectFill
        // Cut off the edges that may be overhanging
        imageView.clipsToBounds = true
        
        // Add thre image inside the overlay view
        playerController.contentOverlayView?.addSubview(imageView)
        
        // Add constraints for the width/height and x/y
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.heightAnchor.constraint(equalTo: imageView.superview!.heightAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.superview!.widthAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: imageView.superview!.bottomAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: imageView.superview!.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: imageView.superview!.trailingAnchor).isActive = true
    }
    
    
    // MARK: - Coordinator
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(playerPresentationState: $playerPresentationState)
    }
    
    
    // The coordinator can be accessed from any thread but the presentation state can only be accessed from the main actor.
    // Therefore the delegate methods for AVPlayerViewControllerDelegate must also be isolated on the main actor
    public class Coordinator: NSObject, @MainActor AVPlayerViewControllerDelegate {
        
        @MainActor @Binding private var playerPresentationState: MultimediaPlayerPresentation
                
        init(playerPresentationState: Binding<MultimediaPlayerPresentation>) {
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
