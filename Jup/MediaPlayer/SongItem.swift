//
//  SongItem.swift
//  Jup
//
//  Created by Nick Venanzi on 12/25/20.
//

protocol SongItem {
    
    var uri: String { get }
    var artistName: String { get }
    var songTitle: String { get }
    var albumURL: String { get }
    var songLength: UInt { get }
    var albumArtwork: UIImage? { get set }
    var likes: Int { get set }
    var added: Bool { get set }

    
    func retrieveArtwork(completionHandler: @escaping (_ image: UIImage) -> ())
    
}

extension SongItem {
    
    func getSongMap() -> [String: Any] {
        return ["uri": uri, "artistName": artistName, "songTitle": songTitle,
                "albumURL": albumURL, "songLength": songLength, "progress": 0.0, "likes": likes]
    }
    
    func getQueueSongItem() -> QueueSongItem {
        return QueueSongItem(title: songTitle, artist: artistName, uri: uri, albumArtwork: albumArtwork ?? UIImage(), contributor: "", likes: likes)
    }
}

