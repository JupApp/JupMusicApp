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
    
    var state: State
    
    var queue: [String] = []
    var songMap: [String: SongItem] = [:]
    var currentSong: SongItem?
    
    var parentVC: QueueVC
    var mediaPlayer: MediaPlayer?
    
//    let uris: [String] = ["spotify:track:2EjXfH91m7f8HiJN1yQg97", "spotify:track:6HlqioVbMHWnPOmm5Wf7NN","spotify:track:4jWr4c9xp3D2QBd7I7xEqn", "spotify:track:609qKv3KPAbdtp0LQH2buA", "spotify:track:1TwLKNsCnhi1HxbIi4bAW0"]
//    var uri_count = 0
    init(_ platform: Platform, _ queueVC: QueueVC) {
        self.parentVC = queueVC
        if platform == .APPLE_MUSIC {
            mediaPlayer = AppleMusicMediaPlayer()
        } else if platform == .SPOTIFY {
            mediaPlayer = SpotifyMediaPlayer()
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.state = .NO_SONG_SET
        appDelegate.triggerAlertInVC = {
            self.parentVC.present(self.parentVC.failedSpotifyConnectionAlert, animated: true)
        }
    }
    
    var songTimer: Timer?
    
    func play() {
        switch (state) {
        case .NO_SONG_SET:
            if !queue.isEmpty {
                songTimer = nil
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            break
        case .PAUSED:
            songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            mediaPlayer?.play()
            state = .PLAYING
            // ALERT VIA BTCommunication with new Snapshot
            break
        }
    }
    
    func pause() {
        switch (state) {
        case .NO_SONG_SET:
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            songTimer = nil
            mediaPlayer?.pause()
            state = .PAUSED
            // ALERT VIA BTCommunication with new Snapshot
            break
        case .PAUSED:
            break
        }
    }
    
    func skip() {
        switch (state) {
        case .NO_SONG_SET:
            if !queue.isEmpty {
                songTimer = nil
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            if !queue.isEmpty {
                songTimer = nil
                mediaPlayer?.pause()
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        case .PAUSED:
            if !queue.isEmpty {
                songTimer = nil
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        }
    }
    
    /*
    Function assumes there is a song Up next in the queue, that if there
    is a current song playing, it is already paused, and that the songTimer is nil.
    */
    func transitionToNextSong() {
        if queue.isEmpty {
            self.state = .NO_SONG_SET
            return
        }
        let nextSongURI: String = queue.remove(at: 0)
        let nextSongItem: SongItem = songMap.removeValue(forKey: nextSongURI)!
        
        mediaPlayer?.transitionNextSong(nextSongItem, completionHandler: { (error) in
            if let _ = error {
                // assert alert here?
                fatalError("Failed to transition to Next Song")
            } else {
                self.state = .PLAYING
                self.songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
                self.currentSong = nextSongItem
                self.updateAlbumArtwork()
            }
        })
    }
    
    func addSong() {
        
    }
    
    func likeSong() {
        
    }
    
    func updateQueueWithSnapshot(_ snapshot: [String: Any]) {
        fatalError()
    }
    
    func loadQueueIntoPlayer() {
        let songItemArray = queue.map { (uri) -> SongItem in self.songMap[uri]! }
        self.mediaPlayer?.loadEntireQueue(songItemArray, completionHandler: { (e) in })
    }

    /*
     -if at end up of song, stops timer and calls transitionToNextSong()
     -updates progress bar
     */
    @objc func timerFired() {
        mediaPlayer?.getTimeInfo(completionHandler: { (timeLeft, songDuration) in
            UIView.animate(withDuration: 1.0) {
                let progress = Float(1.0 - (timeLeft/songDuration))
                self.parentVC.nowPlayingProgress.setProgress(progress, animated: true)
                self.parentVC.nowPlayingProgress.setNeedsDisplay()
            }
            if timeLeft < 1100 {
                self.mediaPlayer?.pause()
                self.songTimer = nil
                if self.queue.isEmpty {
                    self.state = .NO_SONG_SET
                } else {
                    self.state = .TRANSITIONING
                    self.transitionToNextSong()
                }
            }
        })
    }
    
    
}
