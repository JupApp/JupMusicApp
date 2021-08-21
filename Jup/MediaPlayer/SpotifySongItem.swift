//
//  SpotifySongItem.swift
//  Jup
//
//  Created by Nick Venanzi on 12/25/20.
//
class AlbumURLString: NSObject, SPTAppRemoteImageRepresentable {
    var imageIdentifier: String
    
    init(_ string: String) {
        imageIdentifier = string
    }
}

class SpotifySongItem: NSObject, SongItem, SPTAppRemoteContentItem {
    
    static func == (lhs: SpotifySongItem, rhs: SpotifySongItem) -> Bool {
        return lhs.uri == rhs.uri
    }
    
    var title: String?
    var subtitle: String?
    var identifier: String { return uri }
    var isAvailableOffline: Bool = true
    var isPlayable: Bool = true
    var isContainer: Bool = false
    var children: [SPTAppRemoteContentItem]?
    var imageIdentifier: String { return albumURL }
    
    
    var uri: String
    var artistName: String
    var songTitle: String
    var albumURL: String
    var songLength: UInt
    var albumArtwork: UIImage?
    var likes: Set<String>
    var added: Bool = false
    var platform: Platform = .SPOTIFY
    var contributor: String
    var timeAdded: Date
    
    convenience init(id: String, artist: String, song: String, albumURL: String, length: UInt, contributor: String) {
        self.init(id: id, artist: artist, song: song, albumURL: albumURL, length: length, likes: Set(), contributor: contributor, timeAdded: Date())
    }
    
    required init(id: String, artist: String, song: String, albumURL: String, length: UInt, likes: Set<String>, contributor: String, timeAdded: Date) {
        self.uri = id
        self.artistName = artist
        self.songTitle = song
        self.albumURL = albumURL
        self.songLength = length
        self.likes = likes
        self.contributor = contributor
        self.timeAdded = timeAdded
    }
    
    func retrieveArtwork(completionHandler: @escaping (_ image: UIImage) -> ()) {
        if let artwork = self.albumArtwork {
            completionHandler(artwork)
            return
        }
        SpotifySongItem.retrieveArtwork(albumURL) { image in
            self.albumArtwork = image
            completionHandler(image)
        }
    }
    
    func copy() -> SongItem {
        return SpotifySongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes, contributor: contributor, timeAdded: timeAdded)
    }
    
    
}
