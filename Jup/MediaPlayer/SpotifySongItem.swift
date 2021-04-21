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
    var likes: Int = 0
    var added: Bool = false
    var platform: Platform = .SPOTIFY
    
    required init(id: String, artist: String, song: String, albumURL: String, length: UInt) {
        self.uri = id
        self.artistName = artist
        self.songTitle = song
        self.albumURL = albumURL
        self.songLength = length
    }
    
    func retrieveArtwork(completionHandler: @escaping (_ image: UIImage) -> ()) {
        if let artwork = albumArtwork {
            completionHandler(artwork)
            return
        }
        guard let url: URL = URL(string: albumURL) else {
            completionHandler(UIImage())
            return
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data else { completionHandler(UIImage()); return }
            DispatchQueue.main.async {
                self.albumArtwork = UIImage(data: data)
                completionHandler(self.albumArtwork ?? UIImage())
            }
        }
        task.resume()
    }
    
    
}
