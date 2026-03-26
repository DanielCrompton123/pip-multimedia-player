//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 25/03/2026.
//

import Foundation
import MediaPlayer


public struct MultimediaMetadata: Sendable, Equatable {
    public init(title: String? = nil, creator: String? = nil, thumbnail: UIImage? = nil, playbackDuration: Double? = nil) {
        self.title = title
        self.creator = creator
        self.thumbnail = thumbnail
        self.playbackDuration = playbackDuration
    }
    
    public let title: String?
    public let creator: String?
    public let thumbnail: UIImage?
    public let playbackDuration: TimeInterval?
    
    public var artwork: MPMediaItemArtwork? {
        guard let thumbnail else { return nil }
        return MPMediaItemArtwork(image: thumbnail)
    }
    
    public var dictionary: [String:Any] {
        var dict = [
            MPMediaItemPropertyTitle: title as Any,
            MPMediaItemPropertyComposer: creator as Any,
            MPMediaItemPropertyPlaybackDuration: playbackDuration as Any
        ]
        
        if let artwork {
            dict[MPMediaItemPropertyArtwork] = artwork as Any
        }
        
        return dict
    }
    
}
