//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 26/03/2026.
//

import Foundation
import MediaPlayer


@MainActor
struct NowPlayingHelper {
    private init() { }
    
    
    static private var commandCentre: MPRemoteCommandCenter { .shared() }
    static private var infoCentre: MPNowPlayingInfoCenter { .default() }
    
    
    static func addCommands(for player: AudioPlayer) {
        commandCentre.pauseCommand.addTarget { event in
            player.pause()
            return .success
        }
        commandCentre.playCommand.addTarget { event in
            player.play()
            return .success
        }
        commandCentre.togglePlayPauseCommand.addTarget { event in
            player.togglePlayPause()
            return .success
        }
        commandCentre.stopCommand.addTarget { event in
            player.stop()
            return .success
        }
        commandCentre.skipForwardCommand.addTarget { event in
            player.skip()
            return .success
        }
        commandCentre.skipBackwardCommand.addTarget { event in
            player.backtrack()
            return .success
        }
        
        commandCentre.skipForwardCommand.preferredIntervals = [player.backtrackSkipInterval.rawValue as NSNumber]
        commandCentre.skipBackwardCommand.preferredIntervals = [player.backtrackSkipInterval.rawValue as NSNumber]
        
        commandCentre.skipForwardCommand.addTarget {
            guard let event = $0 as? MPSkipIntervalCommandEvent else { return .commandFailed }
            player.seek(to: player.currentTime + event.interval)
            return .success
        }
        
        commandCentre.skipBackwardCommand.addTarget {
            guard let event = $0 as? MPSkipIntervalCommandEvent else { return .commandFailed }
            player.seek(to: player.currentTime + event.interval)
            return .success
        }
        
        commandCentre.changePlaybackPositionCommand.addTarget {
            guard let event = $0 as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            player.seek(to: event.positionTime)
            return .success
        }

    }
    
    static func addCommands(for player: AVPlayer) {
        commandCentre.pauseCommand.addTarget { event in
            player.pause()
            return .success
        }
        commandCentre.playCommand.addTarget { event in
            player.play()
            return .success
        }
        commandCentre.togglePlayPauseCommand.addTarget { event in
            switch player.timeControlStatus {
                case .paused:
                    player.play()
                case .waitingToPlayAtSpecifiedRate:
                    player.pause()
                case .playing:
                    player.pause()
                @unknown default:
                    return .commandFailed
            }
            return .success
        }
        commandCentre.stopCommand.addTarget { event in
            player.replaceCurrentItem(with: nil)
            return .success
        }
        
        commandCentre.skipForwardCommand.addTarget {
            guard let event = $0 as? MPSkipIntervalCommandEvent else { return .commandFailed }
            player.seek(to: player.currentTime() + CMTime(seconds: event.interval, preferredTimescale: 600))
            return .success
        }
        
        commandCentre.skipBackwardCommand.addTarget {
            guard let event = $0 as? MPSkipIntervalCommandEvent else { return .commandFailed }
            player.seek(to: player.currentTime() - CMTime(seconds: event.interval, preferredTimescale: 600))
            return .success
        }
        
        commandCentre.changePlaybackPositionCommand.addTarget {
            guard let event = $0 as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            player.seek(to: CMTime(seconds: event.timestamp, preferredTimescale: 600))
            return .success
        }
    }
    
    static func removeCommands() {
        // nil to remove all targets
        commandCentre.pauseCommand.removeTarget(nil)
        commandCentre.playCommand.removeTarget(nil)
        commandCentre.stopCommand.removeTarget(nil)
        commandCentre.togglePlayPauseCommand.removeTarget(nil)
        commandCentre.skipForwardCommand.removeTarget(nil)
        commandCentre.skipBackwardCommand.removeTarget(nil)
    }
    
    static func updateNowPlayingData<M: MultimediaMetadata>(_ metadata: M) {
        if infoCentre.nowPlayingInfo == nil {
            infoCentre.nowPlayingInfo = metadata.dictionary
        } else {
            infoCentre.nowPlayingInfo?.merging(metadata.dictionary, uniquingKeysWith: { (curr, new) in new })
        }
        print("Now playing info dictionary set: \(infoCentre.nowPlayingInfo)")
    }
}
