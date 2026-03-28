# PIPMultimediaPlayer for iOS

In this package I have 2 main things - an `AudioPlayerView` that uses `AudioPlayer` to play simple local audio files. `AudioPlayer` is a wrapper around the AVFoundation `AVAudioPlayer`. 

It also contains a `PiPMultimediaPlayer` which can play both video & audio (the one of its inputs determines which) from a local or remote URL (although only local URLs have been tested. Please open an issue if remote URLs don't work with it.) It is a wrapper round the AVPlayerViewController with some other helpers & functionality.

## Advantages
It has 5 main advantages over the `VideoPlayer` view from the SwiftUI & AVKit bridge:
- It can go in **full screen** - the SwiftUI `VideoPlayer` has its full-screen button hidden for some reason so is limited to inline mode only
- It manages its own audio session so you don't have to do any of that 
- It **uses PiP mode** (picture in picture) - The normal SwiftUI one can't. Once the app is put into the background, the `VideoPlayer` just stops
-  It publishes metadata including title, creator, and artwork, to the now playing info center in the lock screen
- It handles audio files by displaying the thumbnail over the placeholder for `AVPlayerViewController`

## Development
I document my development experience in [this medium article](https://medium.com/@danielcrompton5/swiftui-video-audio-player-with-pip-now-playing-support-5b0b67da0db5). I also include links to my research so please read those as well!

You can also read my [notes on Craft](https://docs.craft.do/editor/d/06ede71e-d97f-a167-f82b-1f8e8c961ff7/D1CEEA89-0ACB-4413-8054-173938E9652B/b/F5E205F9-271C-477C-8491-5FB995B99838?s=Np6BvcP1VpyTP4MWhmGHVzrpBnFrqsJVVKCRU8gSNg3D#A120CB20-A481-4E7C-AA36-DFC3D006166E).
