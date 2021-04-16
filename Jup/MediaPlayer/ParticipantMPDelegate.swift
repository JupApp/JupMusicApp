//
//  ParticipantMPDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit

class ParticipantMPDelegate: MediaPlayerDelegate {
    var songProgress: Progress = Progress()
    
    var currentSong: SongItem?
    var queue: [String] = []
    var songMap: [String : SongItem] = [:]
    
    var mediaPlayer: MediaPlayer?
    var parentVC: QueueVC
    var songTimer: Timer?
    var state: State
    
    init(_ parentVC: QueueVC) {
        self.parentVC = parentVC
        self.state = .NO_SONG_SET
    }
    //dont do anything if participant tries to play pause or skip
    func play() {}
    func pause() {}
    func skip() {}
    
    func transitionToNextSong() {
        if queue.isEmpty {
            state = .NO_SONG_SET
            return
        }
        let nextSongURI: String = queue.remove(at: 0)
        currentSong = songMap.removeValue(forKey: nextSongURI)!
    
        state = .PLAYING
        songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        updateAlbumArtwork()
        updateDataSource()
    }
    
    //should not encounter these functions as a participant
    func addSong(_ songItem: SongItem, _ completionHandler: @escaping () -> ()) { fatalError() }

    func likeSong(_ uri: String, _ liked: Bool) { fatalError() }
    
    func updateQueueWithSnapshot(_ snapshot: [String: Any]) {
        self.songTimer = nil
        self.state = State.init(rawValue: snapshot["state"]! as! Int)!
        if let songMap = snapshot["currentSong"] as? [String: Any] {
            //update progress bar
            let progress = songMap["progress"] as! Float
            self.parentVC.nowPlayingProgress.setProgress(progress, animated: true)
            self.parentVC.nowPlayingProgress.setNeedsDisplay()
            
            if self.parentVC.platform == .APPLE_MUSIC {
                self.currentSong = AppleMusicSongItem(songMap)
            } else if self.parentVC.platform == .SPOTIFY {
                self.currentSong = SpotifySongItem(songMap)
            }
            
            //update album artwork
            self.updateAlbumArtwork()
        }
        
        //load in queue
        if let queueMaps = snapshot["queue"] as? [[String: Any]] {
            let songsInQueue: [SongItem]
            if self.parentVC.platform == .APPLE_MUSIC {
                songsInQueue = queueMaps.map({ (songMap) -> SongItem in
                    AppleMusicSongItem(songMap)
                })
            } else if self.parentVC.platform == .SPOTIFY {
                songsInQueue = queueMaps.map({ (songMap) -> SongItem  in
                    SpotifySongItem(songMap)
                })
            } else {
                fatalError()
            }
            self.queue = songsInQueue.map({ (songItem) -> String in
                songItem.uri
            })
            self.songMap = Dictionary(uniqueKeysWithValues: songsInQueue.map{ ($0.uri, $0) })
            
        }
        updateDataSource()

        if self.state == .PLAYING {
            songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
        
    }
    
    func loadQueueIntoPlayer() {}
    
    /*
     Sets timer at 1 sec interval
     */
    func setTimer() {
        self.songTimer?.invalidate()
        self.songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
    }
    
    @objc func timerFired() {
        let songLength: Float = Float(currentSong!.songLength)
        let previousPlaybackPosition: Float = parentVC.nowPlayingProgress.progress * songLength
        let newPlaybackPosition: Float = previousPlaybackPosition + 1.0
        
        if songLength - newPlaybackPosition > 1100 {
            parentVC.nowPlayingProgress.setProgress(newPlaybackPosition / songLength, animated: true)
            parentVC.nowPlayingProgress.setNeedsDisplay()
        } else if queue.isEmpty {
            state = .NO_SONG_SET
            songTimer = nil
        } else {
            songTimer = nil
            state = .TRANSITIONING
            transitionToNextSong()
        }
    }
    
}


