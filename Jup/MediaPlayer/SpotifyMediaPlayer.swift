//
//  SpotifyMediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
class SpotifySongItemArray: NSObject, SPTAppRemoteContentItem {
    var title: String?
    var subtitle: String?
    var identifier: String = ""
    var uri: String = ""
    var isAvailableOffline: Bool = false
    var isPlayable: Bool = true
    var isContainer: Bool = true
    var children: [SPTAppRemoteContentItem]?
    var imageIdentifier: String = ""
    
    init(_ songItems: [SpotifySongItem]) {
        children = songItems
    }
    
}

class SpotifyMediaPlayer: NSObject, MediaPlayer, SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        self.state = playerState
        print("Name of Track playing: \(self.state?.track.name)\nName of Artist: \(self.state?.track.artist)")
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
                        if let e = error {
                            print(e.localizedDescription)
                            print("Couldn't subscribe to player state changes")
                            completionHandler(SpotifyAppRemoteError())
                            return
                        }
                        self.state = success as? SPTAppRemotePlayerState
                    }
                    self.player?.play(spotifySongItem) { (_, e) in
                        if let _ = e {
                            print("error, its with trying to play song")
                        }
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
    
    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
        guard let spotifyItemList = songItems as? [SpotifySongItem] else {
            fatalError("Cannot Downcast SongItem array to SpotifySongItemArray")
        }
        let containerContentItem = SpotifySongItemArray(spotifyItemList)
        player?.play(containerContentItem) { (_, e) in
            completionHandler(e)
        }
    }
    
    
}
