//
//  HostMPDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit
import MediaPlayer
import StoreKit


class HostMPDelegate: MediaPlayerDelegate {
    var mediaPlayer: MediaPlayer?
    let uris: [String] = ["spotify:track:2EjXfH91m7f8HiJN1yQg97", "6HlqioVbMHWnPOmm5Wf7NN","4jWr4c9xp3D2QBd7I7xEqn", "609qKv3KPAbdtp0LQH2buA", "1TwLKNsCnhi1HxbIi4bAW0"]
    var uri_count = 0
    init(_ platform: Platform) {

        if platform == .APPLE_MUSIC {
            mediaPlayer = AppleMusicMediaPlayer()
        } else if platform == .SPOTIFY {
            mediaPlayer = SpotifyMediaPlayer()
        }
    }
    
    var songTimer: Timer?
    
    func play() {
        let songItem: SongItem = SpotifySongItem(uri: uris[0], artist: "", song: "", albumURL: "", length: 100)
        mediaPlayer?.transitionNextSong(songItem) { (error) in
            if let _ = error {
                print("error accessing remote player and song to play")
                return
            }
            print("Success!!!!!!")
        }
    }
    
    func pause() {
        
    }
    
    func skip() {
        
    }
    
    func addSong() {
        
    }
    
    func likeSong() {
        
    }
    
    func updateQueueWithSnapshot() {
        fatalError()
    }
    
    
}
