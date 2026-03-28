//
//  File.swift
//  MultimediaPlayer
//
//  Created by daniel on 25/03/2026.
//

import Foundation
import MediaPlayer

/// Contains important metadata to display in the Now Playing area of the control centre.  Only contains the static data that varies per track or video father than playback state
public struct NowPlayingMetadata: Sendable, Equatable {
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
}
