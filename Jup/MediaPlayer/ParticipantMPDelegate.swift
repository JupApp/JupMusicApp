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
    
    func addSong(_ songItem: SongItem) {
        self.parentVC.btDelegate.addSongRequest(songItem, false)
    }
    
    func likeSong(_ uri: String, _ liked: Bool, _ likerID: String) {
        self.parentVC.btDelegate.likeSongRequest(uri, liked, likerID)
    }

    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot) {
        self.songTimer?.invalidate()
        self.state = State.init(rawValue: snapshot.state)!
        
        var songItems: [SongItem] = snapshot.songs.map { $0.decodeSong() }
        
        if songItems.count > 0 {
            if self.state != .NO_SONG_SET {
                currentSong = songItems.remove(at: 0)
                print("Time In: \(snapshot.timeIn)")
                //update progress bar
                let timeIn = snapshot.timeIn
                let progress = 1000.0 * Float(timeIn)/Float(currentSong!.songLength)

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
                
        var snap = NSDiffableDataSourceSnapshot<String, QueueSongItem>()
        snap.appendSections(["Queue"])
        snap.appendItems(self.queue.map({ (uri) -> QueueSongItem in
            self.songMap[uri]!.getQueueSongItem()
        }))
        
        let group = DispatchGroup()
        for songItem in songItems {
            DispatchQueue.global(qos: .utility).async(group: group) {
                group.enter()
                songItem.retrieveArtwork { image in
                    self.songMap[songItem.uri]?.albumArtwork = image
                    group.leave()
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) { [weak self] in
            self?.parentVC.datasource.apply(snap, animatingDifferences: true) {
                self?.parentVC.tableView.reloadData()
            }
        }

        if self.state == .PLAYING {
            setTimer()
        }
        
        /*
         Update participant menu
         */
        parentVC.participants = snapshot.participants
        parentVC.participantMenuVC?.tableView.reloadData()
        
    }
    
    func getQueueSnapshot(_ completionHandler: @escaping (QueueSnapshot) -> ()) {
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
        if parentVC.btDelegate == nil {
            return
        }
        let songLength: Float = Float(currentSong!.songLength)/1000.0
        let previousPlaybackPosition: Float = parentVC.nowPlayingProgress.progress * songLength
        let newPlaybackPosition: Float = previousPlaybackPosition + 1.0
        print("\(songLength - newPlaybackPosition) seconds left in song")
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
    }
    
    func returnedToApp() {
        /*
         Need updated queue
         */
        self.parentVC.btDelegate.updateQueueSnapshot()
    }
    
    func clearQueue() {}
    func moveSong(_ startIndex: Int, _ endIndex: Int) {}
    
    func deleteSong(_ uri: String) {
        let index = queue.firstIndex(of: uri)!
        let songItem: SongItem = songMap[queue[index]]!
        self.parentVC.btDelegate.addSongRequest(songItem, true)
    }

}


