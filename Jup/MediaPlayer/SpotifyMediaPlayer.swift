//
//  SpotifyMediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.


class SpotifyMediaPlayer: NSObject, MediaPlayer/*, SPTAppRemotePlayerStateDelegate*/ {

    var player: SPTAppRemotePlayerAPI?

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
                guard appDelegate.appRemote.isConnected else {
                    print("2. \(error ?? SpotifyAppRemoteError())")
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
                    self.player?.play(spotifySongItem) { (_, e) in
                        completionHandler(e)
                        self.player?.enqueueTrackUri(spotifySongItem.uri, callback: { _, _ in })
                    }
                })
                
            }
        } else {
            player?.play(spotifySongItem) { (_, e) in
                if let _ = e {
                    print("3. \(e!)")
                }
                completionHandler(e)
            }
        }
    }
    
    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
        guard let spotifyItemList = songItems as? [SpotifySongItem] else {
            fatalError("Cannot Downcast SongItem array to SpotifySongItemArray")
        }

        self.enqueueSongList(spotifyItemList, 0, completionHandler: completionHandler)
    }
    
    func enqueueSongList(_ songItems: [SpotifySongItem], _ currentIndex: Int, completionHandler: @escaping (Error?) -> ()) {
        if currentIndex == songItems.count {
            self.player?.setRepeatMode(.off)
            completionHandler(nil)
            return
        }
        let nextItem: SpotifySongItem = songItems[songItems.count - 1 - currentIndex]

        self.player?.enqueueTrackUri(nextItem.uri, callback: { (_, e) in
            if let _ = e {
                print("Failed to enqueue track with URI: \(nextItem.songTitle)")
            } else {
                print("Successfully enqueued track: \(nextItem.songTitle)")
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
    
    func nowPlayingInfo(_ completionHandler: @escaping (String?, Bool) -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if !appDelegate.appRemote.isConnected {
            appDelegate.connect("") { _ in
                guard let _ = self.player else {
                    completionHandler(nil, false)
                    return
                }
                self.player?.getPlayerState { (state, error) in
                    if let _ = error {
                        completionHandler(nil, false)
                        return
                    }
                    let currentState = state as? SPTAppRemotePlayerState
                    completionHandler(currentState?.track.uri, !(currentState?.isPaused ?? true))
                }
            }
            return
        }

        self.player?.getPlayerState { (state, error) in
            if let _ = error {
                appDelegate.connect("") { e in
                    if let _ = e {
                        completionHandler(nil, false)
                        return
                    }
                    self.player?.getPlayerState { (state, error) in
                        if let _ = error {
                            completionHandler(nil, false)
                            return
                        }
                        let currentState = state as? SPTAppRemotePlayerState
                        completionHandler(currentState?.track.uri, !(currentState?.isPaused ?? true))
                    }
                }
                return
            }
            let currentState = state as? SPTAppRemotePlayerState
            completionHandler(currentState?.track.uri, !(currentState?.isPaused ?? true))
        }
    }
}
