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
    var platform: Platform { get set }
    var contributor: String { get set }
    var timeAdded: Date { get set }

    init(id: String, artist: String, song: String, albumURL: String, length: UInt, likes: Int, contributor: String, timeAdded: Date)

    func retrieveArtwork(completionHandler: @escaping (_ image: UIImage) -> ())
    func copy() -> SongItem

}

extension SongItem {
    
    func encodeSong(_ addToQueue: Bool = true) -> CodableSong {
        return CodableSong(uri: uri, artistName: artistName, songTitle: songTitle, albumURL: albumURL, songLength: songLength, platform: platform.rawValue, likes: likes, contributor: contributor, timeAdded: timeAdded, add: addToQueue)
    }
    
    func getQueueSongItem() -> QueueSongItem {
        return QueueSongItem(title: songTitle, artist: artistName, uri: uri, albumArtwork: albumArtwork ?? UIImage(), contributor: contributor, likes: likes, timeAdded: timeAdded)
    }
    
    static func retrieveArtwork(_ imageURL: String, completionHandler: @escaping (_ image: UIImage) -> ()) {
        guard let url: URL = URL(string: imageURL) else {
            completionHandler(UIImage())
            return
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, _, _ in
            guard let data = data else { completionHandler(UIImage()); return }
            DispatchQueue.main.async {
                completionHandler(UIImage(data: data) ?? UIImage())
            }
        }
        task.resume()
    }
}

