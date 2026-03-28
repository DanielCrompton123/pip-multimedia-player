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
    
    static func publishMetadata(_ metadata: NowPlayingMetadata, to playerItem: AVPlayerItem) {
        let creator = AVMutableMetadataItem()
        creator.identifier = .commonIdentifierCreator
        creator.value = metadata.creator as NSString
        creator.extendedLanguageTag = "und"
        
        let title = AVMutableMetadataItem()
        title.identifier = .commonIdentifierTitle
        title.value = metadata.title as NSString
        title.extendedLanguageTag = "und"
        
        var artwork: AVMutableMetadataItem?
        if let thumbnailData = metadata.thumbnail.pngData() {
            artwork = AVMutableMetadataItem()
            artwork!.identifier = .commonIdentifierArtwork
            artwork!.value = thumbnailData as NSData
            artwork!.dataType = kCMMetadataBaseDataType_PNG as String
            artwork!.extendedLanguageTag = "und"
        } else {
            print("[MultimediaPlayer: NowPlayingHelper.publishMetadata]: Cannot get the thumbnail's PNG data, so not adding the artwork to the now playing information")
        }
        
        playerItem.externalMetadata = [creator, title, artwork].compactMap(\.self)
    }
}
