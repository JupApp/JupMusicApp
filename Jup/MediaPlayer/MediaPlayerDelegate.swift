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
    var songTimer: Timer? { get set }
    var mediaPlayer: MediaPlayer? { get }
    var state: State { get set }
    var songProgress: Progress { get set }

        
    var queue: [String] { get }
    var songMap: [String: SongItem] { get }
    var currentSong: SongItem? { get }
    
    func play()
    
    func pause()
    
    func skip()
    
    func transitionToNextSong()
    
    func addSong(_ songItem: SongItem, _ completionHandler: @escaping () -> ())
    
    func likeSong(_ uri: String, _ liked: Bool)
    
    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot(_ snapshot: [String: Any])
    
    func getQueueSnapshot() -> [String: Any]
    
    func updateAlbumArtwork()
    
    func updateDataSource()
    
    func setTimer()

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
        print("updateAlbumArtwork called")
        guard let songItem = self.currentSong else {
            return
        }
        print("Song to be displayed: \(songItem.songTitle)")

        songItem.retrieveArtwork { (image) in
            print("Artwork successfully retrieved")
            self.parentVC.nowPlayingAlbum.image = image
            self.parentVC.nowPlayingArtist.text = songItem.artistName
            self.parentVC.nowPlayingTitle.text = songItem.songTitle
        }
    }
    
    func updateDataSource() {
        print("updateDataSource called")
        var snap = NSDiffableDataSourceSnapshot<String, QueueSongItem>()
        snap.appendSections(["Queue"])
        snap.appendItems(queue.map({ (uri) -> QueueSongItem in
            songMap[uri]!.getQueueSongItem()
        }))
        DispatchQueue.main.async {
            parentVC.datasource.apply(snap, animatingDifferences: true)
        }
    }
}
