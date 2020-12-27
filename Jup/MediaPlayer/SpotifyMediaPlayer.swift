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
    }
    
    var player: SPTAppRemotePlayerAPI
    var state: SPTAppRemotePlayerState?
    
    init(_ spotifyPlayer: SPTAppRemotePlayerAPI) {
        player = spotifyPlayer
        player.setRepeatMode(.off)
        super.init()
        player.subscribe { (success, _) in
            guard let state = success as? SPTAppRemotePlayerState else {
                fatalError("Couldn't subscribe to player state changes")
            }
            self.state = state
        }
    }
    
    func play() {
        player.resume()
    }
    
    func pause() {
        player.pause()
    }
    
    func skip() {
        player.skip(toNext: { (_, _) in })
    }
    
    func transitionNextSong(_ songItem: SongItem, completionHandler: @escaping (Error?) -> ()) {
        guard let spotifySongItem = songItem as? SpotifySongItem else {
            fatalError("Passed in Apple Music Song Item into Spotify Media Player")
        }
        player.play(spotifySongItem) { (_, e) in
            completionHandler(e)
        }
    }
    
    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
        guard let spotifyItemList = songItems as? [SpotifySongItem] else {
            fatalError("Cannot Downcast SongItem array to SpotifySongItemArray")
        }
        let containerContentItem = SpotifySongItemArray(spotifyItemList)
        player.play(containerContentItem) { (_, e) in
            completionHandler(e)
        }
    }
    
    
}
