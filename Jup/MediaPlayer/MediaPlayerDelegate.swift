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
        
    var queue: [String] { get }
    var songMap: [String: SongItem] { get }
    var likedSongs: Set<String> { get set }
    var currentSong: SongItem? { get }
    
    func play()
    
    func pause()
    
    func skip()
    
    func transitionToNextSong()
    
    func addSong(_ songItem: SongItem, _ completionHandler: @escaping (Error?) -> ())
    
    func likeSong(_ uri: String, _ liked: Bool, _ completionHandler: @escaping (Error?) -> ())

    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot)
    
    func getQueueSnapshot() -> QueueSnapshot
    
    func updateAlbumArtwork()
    
    func updateDataSource()
    
    func setTimer()
    
    func returnedToApp()

}

extension MediaPlayerDelegate {
    
    func updateAlbumArtwork() {
        guard let songItem = self.currentSong else {
            /*
             Fill in album background with blank image
             */
            self.parentVC.nowPlayingAlbum.image = UIImage(named: "placeHolderImage")
            self.parentVC.nowPlayingArtist.text = "Artist"
            self.parentVC.nowPlayingTitle.text = "Song Title"
            self.parentVC.nowPlayingContributor.text = "Contributor"
            return
        }

        songItem.retrieveArtwork { (image) in
            self.parentVC.nowPlayingAlbum.image = image
            self.parentVC.nowPlayingArtist.text = songItem.artistName
            self.parentVC.nowPlayingTitle.text = songItem.songTitle
            self.parentVC.nowPlayingContributor.text = songItem.contributor
            self.parentVC.propagateImage()
//            self.parentVC.backgroundImageView.image = image
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
