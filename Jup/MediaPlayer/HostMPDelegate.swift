//
//  HostMPDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit
import MediaPlayer
import StoreKit

class LikeError: Error {}
class AddSongError: Error {}

class HostMPDelegate: MediaPlayerDelegate {

    var state: State = .NO_SONG_SET
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
    }
    
    var songTimer: Timer?
    
    func play() {
        switch (self.state) {
        case .NO_SONG_SET:
            if !self.queue.isEmpty {
                self.songTimer?.invalidate()
                self.state = .TRANSITIONING
                self.transitionToNextSong()
                return
            }
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            break
        case .PAUSED:
            self.songTimer?.invalidate()
            self.songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            self.mediaPlayer?.play()
            self.state = .PLAYING
            // ALERT VIA BTCommunication with new Snapshot
            self.parentVC.btDelegate.updateQueueSnapshot()
            return
        }
    }
    
    func pause() {
        switch (self.state) {
        case .NO_SONG_SET:
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            self.songTimer?.invalidate()
            self.mediaPlayer?.pause()
            self.state = .PAUSED
            // ALERT VIA BTCommunication with new Snapshot
            self.parentVC.btDelegate.updateQueueSnapshot()
            return
        case .PAUSED:
            break
        }
    }
    
    func skip() {
        switch (self.state) {
        case .NO_SONG_SET:
            if !self.queue.isEmpty {
                self.songTimer?.invalidate()
                self.state = .TRANSITIONING
                self.transitionToNextSong()
                return
            }
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            if !self.queue.isEmpty {
                self.songTimer?.invalidate()
                self.mediaPlayer?.pause()
                self.state = .TRANSITIONING
                self.transitionToNextSong()
                return
            }
            break
        case .PAUSED:
            if !self.queue.isEmpty {
                self.songTimer?.invalidate()
                self.state = .TRANSITIONING
                self.transitionToNextSong()
                return
            }
            break
        }
    }
    
    /*
    Function assumes there is a song Up next in the queue, that if there
    is a current song playing, it is already paused, and that the songTimer is nil.
    */
    private func transitionToNextSong() {
        print("transition to next song called")
        if queue.isEmpty {
            self.state = .NO_SONG_SET
            parentVC.btDelegate.updateQueueSnapshot()
            return
        }
        DispatchQueue.main.async {
            print("entered async")
            self.parentVC.nowPlayingProgress.setProgress(0, animated: true)
            let nextSongURI: String = self.queue.remove(at: 0)
            let nextSongItem: SongItem = self.songMap.removeValue(forKey: nextSongURI)!
            self.mediaPlayer?.transitionNextSong(nextSongItem, completionHandler: { (error) in
                print("successfully transitioned to next song via mediaPlayer")
                if let _ = error {
                    // assert alert here?
                    fatalError("Failed to transition to Next Song")
                } else {
                    self.state = .PLAYING
                    self.setTimer()
                    self.currentSong = nextSongItem
                    self.updateAlbumArtwork()
                    self.updateDataSource()
                    self.parentVC.btDelegate.updateQueueSnapshot()
                }
            })
        }
    }
    
    func addSong(_ songItem: SongItem) {
        // check if song is different platform than host
        guard parentVC.platform == songItem.platform else {
            fatalError("SongItem of the wrong platform was added")
        }
    
        // check if song is already in queue
        guard self.songMap[songItem.uri] == nil else {
            return
        }
        
        //super simple implementation at the moment
        self.queue.append(songItem.uri)
        self.songMap[songItem.uri] = songItem
        // reset timeAdded for song to present time AKA the time at which the song entered the queue
        self.songMap[songItem.uri]?.timeAdded = Date()
        songItem.retrieveArtwork { _ in
            DispatchQueue.main.async {
                self.parentVC.tableView.reloadData()
            }
        }
        self.updateDataSource()
        self.parentVC.btDelegate.updateQueueSnapshot()
        
        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                /*
                 load into queue updated version of song queue
                 */
                self.loadQueueIntoPlayer()
            }
        }
    }
    
    /*
     Request to like song
     */
    func likeSong(_ uri: String, _ liked: Bool, _ likerID: String) {
        guard let _ = self.songMap[uri] else {
            return
        }
        if liked {
            self.songMap[uri]!.likes.insert(likerID)
        } else {
            self.songMap[uri]!.likes.remove(likerID)
        }
        DispatchQueue.main.async {
            self.parentVC.tableView.reloadData()

            if !self.parentVC.settings.hostEditingOn {
                self.updateQueueOrder()
            }
            
            self.updateDataSource()
            
            self.parentVC.btDelegate.updateQueueSnapshot()
            
            if UIApplication.shared.applicationState == .background {
                /*
                 load into queue updated version of song queue
                 */
                self.loadQueueIntoPlayer()
            }
        }
    }
    
    private func updateQueueOrder() {
        let sortedQueue = queue.sorted(by: { (uri_0, uri_1) -> Bool in
            let likes_0 = songMap[uri_0]!.likes.count
            let likes_1 = songMap[uri_1]!.likes.count
            let timeAdded_0 = songMap[uri_0]!.timeAdded
            let timeAdded_1 = songMap[uri_1]!.timeAdded

            return likes_0 > likes_1 || (likes_0 == likes_1 && timeAdded_0 < timeAdded_1)
        })
        self.queue = sortedQueue
    }
    
    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot) {
        fatalError()
    }
    
    func getQueueSnapshot(_ completionHandler: @escaping (QueueSnapshot) -> ()) {
        var codableSongs: [CodableSong] = self.queue.map({ self.songMap[$0]!.encodeSong() })
        if self.currentSong != nil {
            codableSongs.insert(self.currentSong!.encodeSong(), at: 0)
        }
        self.mediaPlayer?.getTimeInfo(completionHandler: { timeLeft, songDuration in
            var timeIn: Double = songDuration - timeLeft
            if timeLeft < 1.0 || timeIn < 0.0 {
                timeIn = 0
            }
            let snap = QueueSnapshot(songs: codableSongs, timeIn: timeIn, state: self.state.rawValue, participants: self.parentVC.participants, settings: self.parentVC.settings, participantMap: self.parentVC.participantIDsToUsernames)
            completionHandler(snap)
        })
        if self.mediaPlayer == nil {
            let snap = QueueSnapshot(songs: codableSongs, timeIn: 0, state: self.state.rawValue, participants: self.parentVC.participants, settings: self.parentVC.settings, participantMap: self.parentVC.participantIDsToUsernames)
            completionHandler(snap)
        }
    }
    
    func loadQueueIntoPlayer() {
        songTimer?.invalidate()
        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "Test 123") {
            print("Couldn't finish loading songs into queue")
        }
  
        let songItemArray = self.queue.map { (uri) -> SongItem in self.songMap[uri]! }
        self.mediaPlayer?.loadEntireQueue(songItemArray, completionHandler: { (e) in
            UIApplication.shared.endBackgroundTask(bgTask)
        })
    }
    
    /*
     Sets timer at 1 sec interval
     */
    func setTimer() {
        DispatchQueue.main.async {
            self.songTimer?.invalidate()
            self.songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
        }
    }
    
    func stopTimer() {
        DispatchQueue.main.async {
            self.songTimer?.invalidate()
        }
    }

    /*
     -if at end up of song, stops timer and calls transitionToNextSong()
     -updates progress bar
     */
    @objc func timerFired() {
        mediaPlayer?.getTimeInfo(completionHandler: { (timeLeft, songDuration) in
            DispatchQueue.main.async {
                UIView.animate(withDuration: 1.0) {
                    let progress = Float(1.0 - (timeLeft/songDuration))
                    self.parentVC.nowPlayingProgress.setProgress(progress, animated: true)
                }
            }
            if timeLeft < 2.0 {
                print("Time left: \(timeLeft)")
                print("Song Duration: \(songDuration)")
                self.mediaPlayer?.pause()
                self.stopTimer()
                self.state = .TRANSITIONING
                self.transitionToNextSong()
            }
        })
    }
    
    static var returningApp: Bool = false
    /*
     Function addresses any delay in the current queue with songs that
     transitioned during absence.
     */
    func returnedToApp() {
        print("returned to app called")
        if HostMPDelegate.returningApp {
            return
        }
        HostMPDelegate.returningApp = true
        // check the last known state when left
        switch (self.state) {
            case .NO_SONG_SET:
                // pause in case a song is playing
                print("No Song Set")
                self.mediaPlayer?.pause()
                HostMPDelegate.returningApp = false
                return
            case .PAUSED:
                /*
                 One case:
                    1. app is playing, in which we will let them play
                        (user tapped play in Music/Spotiyf app like an idiot)
                 */
                print("Paused")

                break
            case .TRANSITIONING:
                HostMPDelegate.returningApp = false
                print("Transitioning")

                return
            case .PLAYING:
                print("playing")
                break
        }
        self.state = .TRANSITIONING
        // song was playing when left the app last
        self.iterateThroughQueue {
            /*
             Broadcast out new snapshot to participants
             */
            self.parentVC.btDelegate.updateQueueSnapshot()
            HostMPDelegate.returningApp = false
        }
    }
    
    private func iterateThroughQueue(_ completionHandler: @escaping () -> ()) {
        guard let _ = mediaPlayer else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.iterateThroughQueue(completionHandler)
            }
            return
        }
        mediaPlayer?.nowPlayingInfo { (songID, isPlaying) in
            guard let _ = songID else {
                // no song playing
                /*
                 Clear the queue, empty album artork and progressview and stackview
                 */
                self.currentSong = nil
                self.queue = []
                self.songMap = [:]
                self.state = .NO_SONG_SET
                print("No song ID found, pausing, setting progress to 0")

                self.mediaPlayer?.pause()
                self.updateDataSource()
                self.updateAlbumArtwork()
                self.parentVC.nowPlayingProgress.setProgress(0, animated: true)
                completionHandler()
                return
            }
            /*
             if a match, great success, update
             album artwork and set timer
            */
            if songID == self.currentSong?.uri {
                self.updateAlbumArtwork()
                self.updateDataSource()
                /*
                 Two cases:
                    1. app is playing a song, we continue this trend, so state == .PLAYING
                    2. app is paused, we continue the pause state, state == .PAUSED
                 */
                if isPlaying {
                    self.state = .PLAYING
                    self.setTimer()
                } else {
                    self.state = .PAUSED
                    self.songTimer?.invalidate()
                    // manually set progress view while paused
                }
                self.timerFired()
                completionHandler()
                return
            }
            
            /*
             If no match, move on to next song in queue
             */
            if self.queue.isEmpty {
                self.currentSong = nil
                self.state = .NO_SONG_SET
                self.mediaPlayer?.pause()
                self.updateDataSource()
                self.updateAlbumArtwork()
                self.parentVC.nowPlayingProgress.setProgress(0, animated: true)
                completionHandler()
                return
            }

            let nextSongURI: String = self.queue.remove(at: 0)
            self.currentSong = self.songMap.removeValue(forKey: nextSongURI)!
            print("No match, looking into next song: \(self.currentSong!.songTitle)")

            self.iterateThroughQueue(completionHandler)
        }
    }
    
    func clearQueue() {
        queue = []
        songMap = [:]
        currentSong = nil
        state = .NO_SONG_SET
        mediaPlayer?.pause()
        updateDataSource()
        updateAlbumArtwork()
        parentVC.nowPlayingProgress.setProgress(0, animated: true)
        parentVC.btDelegate.updateQueueSnapshot()
    }
    
    func moveSong(_ startIndex: Int, _ endIndex: Int) {
        let songURI: String = queue.remove(at: startIndex)
        queue.insert(songURI, at: endIndex)
        updateDataSource(false)
        parentVC.btDelegate.updateQueueSnapshot()
    }
    
    func deleteSong(_ uri: String) {
        let index: Int = queue.firstIndex(of: uri)!
        queue.remove(at: index)
        updateDataSource(false)
        parentVC.btDelegate.updateQueueSnapshot()
    }
}
