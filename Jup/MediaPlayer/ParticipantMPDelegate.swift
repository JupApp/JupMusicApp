//
//  ParticipantMPDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit

class ParticipantMPDelegate: MediaPlayerDelegate {

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
    func likeSong(_ uri: String, _ likes: Int, _ completionHandler: @escaping () -> ()) { fatalError() }

    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot) {
        self.songTimer?.invalidate()
        self.state = State.init(rawValue: snapshot.state)!

        var songItems: [SongItem] = snapshot.songs.map { $0.decodeSong() }
        
        if songItems.count > 0 {
            currentSong = songItems.remove(at: 0)
            
            //update progress bar
            let timeLeft = snapshot.timeRemaining
            let progress = 1.0 - Float(timeLeft)/Float(currentSong!.songLength)

            self.parentVC.nowPlayingProgress.setProgress(progress, animated: true)
            //update album artwork
            self.updateAlbumArtwork()
            
            queue = songItems.map({ $0.uri })
            songMap = songItems.reduce(into: [String: SongItem]()) { $0[$1.uri] = $1 }
        } else {
            queue = []
            songMap = [:]
        }
        
        updateDataSource()

        if self.state == .PLAYING {
            songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
        
    }
    
    func getQueueSnapshot() -> QueueSnapshot {
        fatalError("Should not be called as a participant")
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
        print("Song length: \(songLength)")
        print("Current Position in Song: \(newPlaybackPosition)\n")
        if songLength - newPlaybackPosition > 0 {
            parentVC.nowPlayingProgress.setProgress(newPlaybackPosition / songLength, animated: true)
            parentVC.nowPlayingProgress.setNeedsDisplay()
        } else if queue.isEmpty {
            state = .NO_SONG_SET
            currentSong = nil
            songTimer?.invalidate()
        } else {
            songTimer?.invalidate()
            state = .TRANSITIONING
            transitionToNextSong()
        }
    }
    
    func returnedToApp() {
    }
}


