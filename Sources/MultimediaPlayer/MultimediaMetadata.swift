//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 25/03/2026.
//

import Foundation
import MediaPlayer

public protocol MultimediaMetadata {
    var dictionary: [String:Any] { get }
}

/// Contains important metadata to display in the Now Playing area of the control centre.  Only contains the static data that varies per track or video father than playback state
public struct NowPlayingMetadata: MultimediaMetadata, Sendable, Equatable {
    public init(
        title: String = "",
        creator: String = "",
        thumbnail: UIImage = .init()
    ) {
        self.title = title
        self.creator = creator
        self.thumbnail = thumbnail
    }
    
    public let title: String
    public let creator: String
    public let thumbnail: UIImage
    
    public var artwork: MPMediaItemArtwork {
        MPMediaItemArtwork(image: thumbnail)
    }
    
    public var dictionary: [String:Any] {
        var dict = [
            MPMediaItemPropertyTitle: title as Any,
            MPMediaItemPropertyArtist: creator as Any,
            MPMediaItemPropertyArtwork: artwork as Any
        ]
        
        return dict
    }
}

/// Contains important playback state details to display in the Now Playing area of the control centre
public struct NowPlayingDynamicData: MultimediaMetadata, Sendable, Equatable {
    
    public init(
        playbackDuration: TimeInterval,
        elapsedTime: TimeInterval,
        playbackRate: Float
    ) {
        self.playbackDuration = playbackDuration
        self.elapsedTime = elapsedTime
        self.playbackRate = playbackRate
    }
    
    public var playbackDuration: TimeInterval
    public var elapsedTime: TimeInterval
    public var playbackRate: Float
    
    public var dictionary: [String : Any] {
        var dict = [
            MPMediaItemPropertyPlaybackDuration: playbackDuration as Any,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedTime as Any,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: playbackRate as Any,
        ]
        
        return dict
    }
}
