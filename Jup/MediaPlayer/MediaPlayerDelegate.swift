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
    var currentSong: SongItem? { get }
    
    func play()
    
    func pause()
    
    func skip()
        
    func addSong(_ songItem: SongItem)
    
    func likeSong(_ uri: String, _ liked: Bool, _ likerID: String)

    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot(_ snapshot: QueueSnapshot)
    
    func getQueueSnapshot(_ completionHandler: @escaping (QueueSnapshot) -> ())
    
    func updateAlbumArtwork()
    
//    func updateDataSource(_ animate: Bool)
    
    func setTimer()
    
    func returnedToApp()
    
    func clearQueue()
    
    func moveSong(_ startIndex: Int, _ endIndex: Int)
    
    func deleteSong(_ uri: String)

}

extension MediaPlayerDelegate {
    
    func updateAlbumArtwork() {
        DispatchQueue.main.async {
            guard let songItem = self.currentSong else {
                /*
                 Fill in album background with blank image
                 */
                self.parentVC.nowPlayingAlbum.image = UIImage(named: "placeholderfinal")
                self.parentVC.nowPlayingArtist.text = ""
                self.parentVC.nowPlayingTitle.text = ""
                self.parentVC.nowPlayingContributor.text = ""
                return
            }

            songItem.retrieveArtwork { (image) in
                self.parentVC.nowPlayingAlbum.image = image
                self.parentVC.nowPlayingArtist.text = songItem.artistName
                self.parentVC.nowPlayingTitle.text = songItem.songTitle
                self.parentVC.nowPlayingContributor.text = self.parentVC.participantIDsToUsernames[songItem.contributor] ?? "Loading..."
                self.parentVC.propagateImage()
            }
        }
    }
    
    func updateDataSource(_ animate: Bool = true) {
        var snap = NSDiffableDataSourceSnapshot<String, QueueSongItem>()
        snap.appendSections(["Queue"])
        snap.appendItems(queue.map({ (uri) -> QueueSongItem in
            print(songMap[uri]?.songTitle ?? "")
            return songMap[uri]!.getQueueSongItem()
        }))
        DispatchQueue.main.async {
            parentVC.datasource.apply(snap, animatingDifferences: animate)
        }
    }
}
