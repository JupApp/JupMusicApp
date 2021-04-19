//
//  SpotifyMediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.


class SpotifyMediaPlayer: NSObject, MediaPlayer/*, SPTAppRemotePlayerStateDelegate*/ {
//    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
//        self.state = playerState
//        print("Name of Track playing: \(self.state?.track.name)\nName of Artist: \(self.state?.track.artist)\nPosition In Track: \(self.state?.playbackPosition)\n  out of: \(self.state?.track.duration)")
//    }
    var player: SPTAppRemotePlayerAPI?
//    var state: SPTAppRemotePlayerState?

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
        print("Transitioning to spotify song: \(songItem.songTitle)")
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if player == nil || !appDelegate.appRemote.isConnected {
            appDelegate.connect(songItem.uri) { error in
                if let _ = error {
                    completionHandler(SpotifyAppRemoteError())
                    return
                }
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
//                    self.player?.delegate = self
//                    self.player?.subscribe { (success, error) in
//                        if let _ = error {
//                            completionHandler(SpotifyAppRemoteError())
//                            return
//                        }
//                        self.state = success as? SPTAppRemotePlayerState
//                    }
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
    func clearQueue(completionHandler: @escaping () -> ()) {
        self.player?.getPlayerState({ (state, error) in
            if let _ = error {
                print("failed to retrieve state information, cannot clear queue")
                completionHandler()
                return
            }
            let currentState = state as! SPTAppRemotePlayerState
            self.clearQueueHelper {
                self.player?.play(currentState.track.uri, callback: { (_, e) in
                    if let _ = e {
                        print("Failed to resume playing song after clearing queue")
                        completionHandler()
                        return
                    }
                    self.player?.seek(toPosition: currentState.playbackPosition, callback: { (_, e) in
                        if let _ = e {
                            print("Failed to resume playing song to previous playback position after clearing the queue")
                        }
                        completionHandler()
                    })
                })
            }
        })
    }
    
    func clearQueueHelper(completionHandler: @escaping () -> ()) {
        self.player?.skip(toNext: { (_, e) in
            if let _ = e {
                print("Reached end of skipping in queue, will now resume playing current song")
                completionHandler()
            } else {
                print("Will continue skipping songs until end is reached")
                self.clearQueueHelper(completionHandler: completionHandler)
            }
        })
    }
    
    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
        guard let spotifyItemList = songItems as? [SpotifySongItem] else {
            fatalError("Cannot Downcast SongItem array to SpotifySongItemArray")
        }
//        clearQueue {
            self.enqueueSongList(spotifyItemList, 0, completionHandler: completionHandler)
//        }
    }
    
    func enqueueSongList(_ songItems: [SpotifySongItem], _ currentIndex: Int, completionHandler: @escaping (Error?) -> ()) {
        if currentIndex == songItems.count {
            completionHandler(nil)
            return
        }
        print("Current Index: \(currentIndex)\nSongList Last Index: \(songItems.endIndex)")
        let nextItem: SpotifySongItem = songItems[songItems.endIndex - currentIndex - 1]
        self.player?.enqueueTrackUri(nextItem.uri, callback: { (_, e) in
            if let _ = e {
                print("Failed to enqueue track with URI: \(nextItem.uri)")
            } else {
                print("Successfully enqueued track with URI: \(nextItem.uri)")
            }
            self.enqueueSongList(songItems, currentIndex + 1, completionHandler: completionHandler)
        })
        
    }
    
    func getTimeInfo(completionHandler: @escaping (Double, Double) -> ()) {
        self.player?.getPlayerState({ (state, error) in
            if let _ = error {
                print("failed get player state rip")
            } else {
                let playerState: SPTAppRemotePlayerState = state as! SPTAppRemotePlayerState
                let songDuration: Double = Double(playerState.track.duration) / 1000.0
                let timeLeft: Double = songDuration - (Double(playerState.playbackPosition) / 1000.0)
                completionHandler(timeLeft, songDuration)
            }
        })
    }
    
    func nowPlayingInfo(_ completionHandler: @escaping (String?) -> ()) {
        self.player?.getPlayerState { (state, error) in
            if let _ = error {
                print("failed to retrieve state information, cannot clear queue")
                completionHandler(nil)
            }
            let currentState = state as! SPTAppRemotePlayerState
            completionHandler(currentState.track.uri)
        }
    }
    
}
