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
    func addSong(_ songItem: SongItem, _ completionHandler: @escaping (Error?) -> ()) { fatalError() }
    func likeSong(_ uri: String, _ likes: Int, _ completionHandler: @escaping (Error?) -> ()) { fatalError() }

    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot) {
        self.songTimer?.invalidate()
        self.state = State.init(rawValue: snapshot.state)!

        var songItems: [SongItem] = snapshot.songs.map { $0.decodeSong() }
        
        if songItems.count > 0 {
            if self.state != .NO_SONG_SET {
                currentSong = songItems.remove(at: 0)
                
                //update progress bar
                let timeIn = snapshot.timeIn
                let progress = Float(timeIn)/Float(currentSong!.songLength)

                self.parentVC.nowPlayingProgress.setProgress(progress, animated: true)
                //update album artwork
                self.updateAlbumArtwork()
            }
            
            queue = songItems.map({ $0.uri })
            songMap = songItems.reduce(into: [String: SongItem]()) { $0[$1.uri] = $1 }
        } else {
            queue = []
            songMap = [:]
        }
        
        updateDataSource()
        
        for songItem in songItems {
            songItem.retrieveArtwork { _ in
                self.parentVC.tableView.reloadData()
            }
        }

        if self.state == .PLAYING {
            songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        }
        
        /*
         Update participant menu
         */
        parentVC.host = snapshot.host
        parentVC.participants = snapshot.participants
        print("Host: \(parentVC.host)\nParticipants: \(parentVC.participants)")
        parentVC.participantMenu?.participantTableView.reloadData()
    }
    
    func getQueueSnapshot() -> QueueSnapshot {
        fatalError("Should not be called as a participant")
    }
    
    func loadQueueIntoPlayer() {
        songTimer?.invalidate()
    }
    
    /*
     Sets timer at 1 sec interval
     */
    func setTimer() {
        self.songTimer?.invalidate()
        self.songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
    }
    
    @objc func timerFired() {
        let songLength: Float = Float(currentSong!.songLength)/1000.0
        let previousPlaybackPosition: Float = parentVC.nowPlayingProgress.progress * songLength
        let newPlaybackPosition: Float = previousPlaybackPosition + 1.0
        print("Song length: \(songLength)")
        print("Current Position in Song: \(newPlaybackPosition)\n")
        if songLength - newPlaybackPosition > 0 {
            UIView.animate(withDuration: 1.0) {
                self.parentVC.nowPlayingProgress.setProgress(newPlaybackPosition / songLength, animated: true)
            }
        } else {
            self.songTimer?.invalidate()
            /*
             Write to host to transition songs
             */
            parentVC.btDelegate.updateQueueSnapshot()
        }
//        } else if queue.isEmpty {
//            state = .NO_SONG_SET
//            currentSong = nil
//            songTimer?.invalidate()
//        } else {
//            songTimer?.invalidate()
//            state = .TRANSITIONING
//            transitionToNextSong()
//        }
    }
    
    func returnedToApp() {
        /*
         Need updated queue
         */
        self.parentVC.btDelegate.updateQueueSnapshot()
    }
}


