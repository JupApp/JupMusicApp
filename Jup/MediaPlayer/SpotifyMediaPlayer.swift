//
//  SpotifyMediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

class SpotifyMediaPlayer: MediaPlayer {
    var player: SPTAppRemotePlayerAPI
    
    init(_ spotifyPlayer: SPTAppRemotePlayerAPI) {
        player = spotifyPlayer
        player.setRepeatMode(.off)
        
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
    
    func transitionNextSong() {
        
    }
    
    func loadEntireQueue() {
        
    }
    
    
}
