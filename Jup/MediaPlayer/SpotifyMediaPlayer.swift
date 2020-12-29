//
//  SpotifyMediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
//class SpotifySongItemArray: NSObject, SPTAppRemoteContentItem {
//    var title: String?
//    var subtitle: String?
//    var identifier: String  {
//        if (children != nil) {
//            print("Tried to access identifier")
//        }
//        return ""
//    }
//    var uri: String {
//        if (children != nil) {
//            print("Tried to access uri")
//        }
//        return ""
//    }
//    var isAvailableOffline: Bool = true
//    var isPlayable: Bool = false
//    var isContainer: Bool = true
//    var subChildren: [SPTAppRemoteContentItem]?
//    var children: [SPTAppRemoteContentItem]? {
//        print("Accessing children")
//        return subChildren
//    }
//    var imageIdentifier: String {
//        if (children != nil) {
//            print("Tried to access imageIdentifier")
//        }
//        return ""
//    }
//    
//    init(_ songItems: [SpotifySongItem]) {
//        subChildren = songItems
//    }
//    
//}

class SpotifyMediaPlayer: NSObject, MediaPlayer, SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        self.state = playerState
//        print("Name of Track playing: \(self.state?.track.name)\nName of Artist: \(self.state?.track.artist)\nPosition In Track: \(self.state?.playbackPosition)\n  out of: \(self.state?.track.duration)")
    }
    var player: SPTAppRemotePlayerAPI?
    var state: SPTAppRemotePlayerState?

    func play() {
        player?.resume()
    }
    
    func pause() {
        player?.pause()
    }
    
    func skip() {
        player?.skip(toNext: { (_, _) in })
    }
    
    func transitionNextSong(_ songItem: SongItem, completionHandler: @escaping (Error?) -> ()) {
        guard let spotifySongItem = songItem as? SpotifySongItem else {
            fatalError("Passed in Apple Music Song Item into Spotify Media Player")
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if player == nil || !appDelegate.appRemote.isConnected {
            appDelegate.connect(songItem.uri) {
                guard appDelegate.appRemote.isConnected else {
                    completionHandler(SpotifyAppRemoteError())
                    return
                }
                appDelegate.appRemote.userAPI?.fetchCapabilities(callback: { (result, error) in
                    guard let capability = result as? SPTAppRemoteUserCapabilities else {
                        print("failed to retrieve capabilities")
                        completionHandler(SpotifyAppRemoteError())
                        return
                    }
                    if !capability.canPlayOnDemand {
                        print("no premium")
                        completionHandler(SpotifyAppRemoteError())
                        return
                    }
                    
                    self.player = appDelegate.appRemote.playerAPI
                    self.player?.setRepeatMode(.off)
                    self.player?.delegate = self
                    self.player?.subscribe { (success, error) in
                        if let _ = error {
                            completionHandler(SpotifyAppRemoteError())
                            return
                        }
                        self.state = success as? SPTAppRemotePlayerState
                    }
                    self.player?.play(spotifySongItem) { (_, e) in
//                        if let _ = e {
//                            print("error, its with trying to play song")
//                        }
                        completionHandler(e)
                    }
                })
                
            }
        } else {
            player?.play(spotifySongItem) { (_, e) in
                completionHandler(e)
            }
        }
    }
    
//    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
//        guard let spotifyItemList = songItems as? [SpotifySongItem] else {
//            fatalError("Cannot Downcast SongItem array to SpotifySongItemArray")
//        }
//        let array = [songItems[0] as! SpotifySongItem]
//        let containerContentItem = SpotifySongItemArray(array)
//        player?.play(containerContentItem) { (_, e) in
//            completionHandler(e)
//            if let _ = e {
//                print("attempt to play content item failed")
//            }
//            self.player?.getPlayerState({ (state, error) in
//                var position: Int = 0
//                if state != nil {
//                    position = (state as! SPTAppRemotePlayerState).playbackPosition
//                }
//                self.player?.seek(toPosition: position, callback: { (_, e) in
//                    if e != nil {
//                        print("failed to seek forward")
//                    }
//                    print("Set Playback to: \(self.state?.playbackPosition ?? 0)")
//                })
//            })
//
//        }
//
//    }
    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
        guard let spotifyItemList = songItems as? [SpotifySongItem] else {
            fatalError("Cannot Downcast SongItem array to SpotifySongItemArray")
        }
        enqueueSongList(spotifyItemList, 0, completionHandler: completionHandler)
    }
    
    func enqueueSongList(_ songItems: [SpotifySongItem], _ currentIndex: Int, completionHandler: @escaping (Error?) -> ()) {
        if currentIndex == songItems.count {
            completionHandler(nil)
            return
        }
        let nextItem: SpotifySongItem = songItems[songItems.endIndex - currentIndex]
        self.player?.enqueueTrackUri(nextItem.uri, callback: { (_, e) in
            if let _ = e {
                print("Failed to enqueue track with URI: \(nextItem.uri)")
            } else {
                print("Successfully enqueued track with URI: \(nextItem.uri)")
            }
            self.enqueueSongList(songItems, currentIndex + 1, completionHandler: completionHandler)
        })
        
    }

    
    
}
