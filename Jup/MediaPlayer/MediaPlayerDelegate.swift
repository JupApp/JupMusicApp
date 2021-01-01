//
//  MediaPlayerDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit

enum State: Int {
    case PLAYING = 0
    case PAUSED = 1
    case TRANSITIONING = 2
    case NO_SONG_SET = 3
}

protocol MediaPlayerDelegate {
    var parentVC: QueueVC { get }
    var songTimer: Timer? { get }
    var mediaPlayer: MediaPlayer? { get }
    var state: State { get set }
        
    var queue: [String] { get }
    var songMap: [String: SongItem] { get }
    var currentSong: SongItem? { get }
    
    func play()
    
    func pause()
    
    func skip()
    
    func transitionToNextSong()
    
    func addSong()
    
    func likeSong()
    
    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot(_ snapshot: [String: Any])
    
    func getQueueSnapshot() -> [String: Any]
    
    func updateAlbumArtwork()

}

extension MediaPlayerDelegate {
    
    func getQueueSnapshot() -> [String: Any] {
        var snapshot: [String: Any] = [:]
        snapshot["state"] = state.rawValue
        snapshot["currentSong"] = currentSong?.getSongMap() ?? "null"
        snapshot["queue"] = queue.map({ (uri) -> [String: Any] in
            songMap[uri]!.getSongMap()
        })
        return snapshot
    }
    
    func updateAlbumArtwork() {
        guard let songItem = self.currentSong else {
            return
        }
        songItem.retrieveArtwork { (image) in
            self.parentVC.nowPlayingAlbum.image = image
            self.parentVC.nowPlayingArtist.text = songItem.artistName
            self.parentVC.nowPlayingTitle.text = songItem.songTitle
        }
    }
}
