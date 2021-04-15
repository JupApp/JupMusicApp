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

    init(_ platform: Platform, _ queueVC: QueueVC) {
        self.parentVC = queueVC
        if platform == .APPLE_MUSIC {
            mediaPlayer = AppleMusicMediaPlayer()
        } else if platform == .SPOTIFY {
            mediaPlayer = SpotifyMediaPlayer()
        }
        self.state = .NO_SONG_SET
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
                self.updateDataSource()
                //
                // ALERT VIA BTCommunication with new Snapshot
                //
            }
        })
    }
    
    func addSong(_ songItem: SongItem) {
        //super simple implementation at the moment
        queue.append(songItem.uri)
        songMap[songItem.uri] = songItem
        updateDataSource()
        //
        //alert via BT of the queue change
        //
    }
    
    func likeSong(_ uri: String, _ liked: Bool) {
        guard let _ = songMap[uri] else {
            //
            //alert via BT that the song is no longer available in queue for liking
            //
            return
        }
        songMap[uri]!.likes += liked ? 1 : -1
        if (parentVC.queueType == .VOTING) {
            updateQueueOrder()
        }
        //
        //alert via BT of the queue change
        //
        updateDataSource()
    }
    
    func updateQueueOrder() {
        let enumerated: [(Int, String)] = Array(self.queue.enumerated())
        let sortedEnumeration = enumerated.sorted(by: { (tup_0, tup_1) -> Bool in
            let (i_0, uri_0) = tup_0
            let (i_1, uri_1) = tup_1
            let likes_0 = songMap[uri_0]!.likes
            let likes_1 = songMap[uri_1]!.likes
            return likes_0 > likes_1 || (likes_0 == likes_1 && i_0 < i_1)
        })
        self.queue = sortedEnumeration.map({ (tuple) -> String in tuple.1 })
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
                print("Time left: \(timeLeft)")
                print("Song Duration: \(songDuration)")
                let progress = Float(1.0 - (timeLeft/songDuration))
                self.parentVC.nowPlayingProgress.setProgress(progress, animated: true)
                self.parentVC.nowPlayingProgress.setNeedsDisplay()
                self.parentVC.tableView.setNeedsDisplay()
            }
            if timeLeft < 1.1 {
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
