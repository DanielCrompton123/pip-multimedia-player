//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 24/03/2026.
//

import SwiftUI
import AVKit


public struct PiPVideoPlayer: UIViewControllerRepresentable {
    
    private let player: AVPlayer
    
    public init(player: AVPlayer) {
        self.player = player
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
        
        return playerController
    }
    
    // Remember: Called when the CALLEE swiftUI view updates the state that this view depends on
    public func updateUIViewController(_ playerViewController: AVPlayerViewController, context: Context) {
        
    }
    
    
    // MARK: Coordinator
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        
        public func playerViewController(
            _ playerViewController: AVPlayerViewController,
            failedToStartPictureInPictureWithError error: any Error
        ) {
            print("[PiPViewoPlayer.playerViewControllerFailedToStartPictureInPictureWithError]: Error = \(error)")
        }
        
    }
}
 
