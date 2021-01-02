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
    
    func addSong(_ songItem: SongItem)
    
    func likeSong(_ uri: String, _ liked: Bool)
    
    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot(_ snapshot: [String: Any])
    
    func getQueueSnapshot() -> [String: Any]
    
    func updateAlbumArtwork()
    
    func updateDataSource()

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
    
    func updateDataSource() {
//        var snap = NSDiffableDataSourceSnapshot<String, SongTableItem>()
//        snap.appendSections(["Queue"])
//        snap.appendItems(queue.map({ (uri) -> SongTableItem in
//            songMap[uri]!.getSongTableItem()
//        }))
//        print("\n\n\n\nItems in Data source: \(snap.numberOfItems)\n\n\n\n")
//        parentVC.datasource.apply(snap, animatingDifferences: true)
    }
}
