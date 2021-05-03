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
    
    var state: State
    
    var queue: [String] = []
    var songMap: [String: SongItem] = [:]
    var likedSongs: Set<String> = Set<String>()
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
    
    var songTimer: Timer? {
        willSet {
            songTimer?.invalidate()
        }
    }
    
    func play() {
        switch (state) {
        case .NO_SONG_SET:
            if !queue.isEmpty {
                songTimer?.invalidate()
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            break
        case .PAUSED:
            songTimer?.invalidate()
            songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
            mediaPlayer?.play()
            state = .PLAYING
            // ALERT VIA BTCommunication with new Snapshot
            parentVC.btDelegate.updateQueueSnapshot()
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
            songTimer?.invalidate()
            mediaPlayer?.pause()
            state = .PAUSED
            // ALERT VIA BTCommunication with new Snapshot
            parentVC.btDelegate.updateQueueSnapshot()
            break
        case .PAUSED:
            break
        }
    }
    
    func skip() {
        switch (state) {
        case .NO_SONG_SET:
            if !queue.isEmpty {
                songTimer?.invalidate()
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        case .TRANSITIONING:
            break
        case .PLAYING:
            if !queue.isEmpty {
                songTimer?.invalidate()
                mediaPlayer?.pause()
                state = .TRANSITIONING
                transitionToNextSong()
            }
            break
        case .PAUSED:
            if !queue.isEmpty {
                songTimer?.invalidate()
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
            parentVC.btDelegate.updateQueueSnapshot()
            return
        }
        parentVC.nowPlayingProgress.setProgress(0, animated: true)
        let nextSongURI: String = queue.remove(at: 0)
        likedSongs.remove(nextSongURI)
        let nextSongItem: SongItem = songMap.removeValue(forKey: nextSongURI)!
        mediaPlayer?.transitionNextSong(nextSongItem, completionHandler: { (error) in
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
    
    func addSong(_ songItem: SongItem, _ completionHandler: @escaping (Error?) -> ()) {
        print("MPDelegate add Song called, type: \(songItem.platform)")
        // check if song is different platform than host
        guard parentVC.platform == songItem.platform else {
            fatalError("SongItem of the wrong platform was added")
        }
        // check if song is already in queue
        guard songMap[songItem.uri] == nil else {
            completionHandler(AddSongError())
            return
        }
        
        //super simple implementation at the moment
        queue.append(songItem.uri)
        songMap[songItem.uri] = songItem
        songItem.retrieveArtwork { _ in
            print("Artowrk retrieved, now update")
            self.parentVC.tableView.reloadData()
        }
        updateDataSource()
        
        parentVC.btDelegate.updateQueueSnapshot()
        completionHandler(nil)
        
        if UIApplication.shared.applicationState == .background {
            /*
             load into queue updated version of song queue
             */
            print("about to load queue")
            self.loadQueueIntoPlayer()
        }
    }
    
    /*
     Request to like song
     */
    func likeSong(_ uri: String, _ liked: Bool, _ completionHandler: @escaping (Error?) -> ()) {
        guard let _ = songMap[uri] else {
            completionHandler(LikeError())
            return
        }
        songMap[uri]!.likes += (liked ? 1 : -1)
        
        if (parentVC.queueType == .VOTING) {
            updateQueueOrder()
        }
        completionHandler(nil)

        updateDataSource()
        
        parentVC.btDelegate.updateQueueSnapshot()
        
        if UIApplication.shared.applicationState == .background {
            /*
             load into queue updated version of song queue
             */
            print("about to load queue")
            self.loadQueueIntoPlayer()
        }
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
    
    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot) {
        fatalError()
    }
    
    func getQueueSnapshot() -> QueueSnapshot {
        /*
         Wake up timer thread and see if song Transition needs to occur
         */
        print("In Background state: \(UIApplication.shared.applicationState == .background)")
        
        var codableSongs: [CodableSong] = queue.map({ self.songMap[$0]!.encodeSong() })
        if currentSong != nil {
            codableSongs.insert(currentSong!.encodeSong(), at: 0)
        }
        let timeIn: Int = Int(self.parentVC.nowPlayingProgress.progress * Float(self.currentSong?.songLength ?? 0))
        return QueueSnapshot(songs: codableSongs, timeIn: timeIn, state: state.rawValue, participants: parentVC.participants, host: parentVC.host)
    }
    
    func loadQueueIntoPlayer() {
        songTimer?.invalidate()
        let songItemArray = queue.map { (uri) -> SongItem in self.songMap[uri]! }
        let bgTask = UIApplication.shared.beginBackgroundTask(withName: "Test 123") {
             print("Couldn't finish loading songs into queue")
        }
        self.mediaPlayer?.loadEntireQueue(songItemArray, completionHandler: { (e) in
            UIApplication.shared.endBackgroundTask(bgTask)
        })
    }
    
    /*
     Sets timer at 1 sec interval
     */
    func setTimer() {
        self.songTimer?.invalidate()
        self.songTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerFired), userInfo: nil, repeats: true)
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
            }
            if timeLeft < 2.0 {
                self.mediaPlayer?.pause()
                self.songTimer?.invalidate()
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
        if HostMPDelegate.returningApp {
            return
        }
        HostMPDelegate.returningApp = true
        // check the last known state when left
        switch (state) {
            case .NO_SONG_SET:
                print("NO SONG SET");
                // pause in case a song is playing
                self.mediaPlayer?.pause()
                HostMPDelegate.returningApp = false
                return
            case .PAUSED:
                print("PAUSED")
                /*
                 One case:
                    1. app is playing, in which we will let them play
                        (user tapped play in Music/Spotiyf app like an idiot)
                 */
                break
            case .TRANSITIONING: HostMPDelegate.returningApp = false; return
            case .PLAYING: break
        }
        self.state = .TRANSITIONING
        // song was playing when left the app last
        iterateThroughQueue {
            /*
             Broadcast out new snapshot to participants
             */
            print("about to enter delay block")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("loading queue soon")
                self.parentVC.btDelegate.updateQueueSnapshot()
                HostMPDelegate.returningApp = false
            }
        }
    }
    
    private func iterateThroughQueue(_ completionHandler: @escaping () -> ()) {
        mediaPlayer!.nowPlayingInfo { (songID, isPlaying) in
            guard let _ = songID else {
                // no song playing
                print("SongID is nil")
                /*
                 Clear the queue, empty album artork and progressview and stackview
                 */
                self.currentSong = nil
                self.state = .NO_SONG_SET
                self.mediaPlayer?.pause()
                self.updateDataSource()
                self.updateAlbumArtwork()
                self.parentVC.nowPlayingProgress.setProgress(0, animated: true)
                completionHandler()
                return
            }
            print("Song ID: \(songID!)")
            print("CurrentSong ID: \(self.currentSong?.uri ?? "")")
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
                print("Matched with \(self.currentSong?.songTitle ?? "")")
                self.timerFired()
                completionHandler()
                return
            }
            
            /*
             If no match, move on to next song in queue
             */
            if self.queue.isEmpty {
                print("Queue is empty")
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
            self.likedSongs.remove(nextSongURI)
            self.currentSong = self.songMap.removeValue(forKey: nextSongURI)!
            self.iterateThroughQueue(completionHandler)
        }
    }
    
    
}
