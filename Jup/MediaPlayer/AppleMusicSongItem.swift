//
//  AppleMusicSongItem.swift
//  Jup
//
//  Created by Nick Venanzi on 12/25/20.
//



class AppleMusicSongItem: SongItem, Hashable {
    

    static func == (lhs: AppleMusicSongItem, rhs: AppleMusicSongItem) -> Bool {
        return lhs.uri == rhs.uri
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }

    var uri: String
    var artistName: String
    var songTitle: String
    var albumURL: String
    var songLength: UInt
    var likes: Int = 0
    var added: Bool = false

    var albumArtwork: UIImage?
    
    init(id: String, artist: String, song: String, albumURL: String, length: UInt) {
        uri = id
        artistName = artist
        songTitle = song
        self.albumURL = albumURL
        songLength = length
    }
    
    init(_ songMap: [String: Any]) {
        self.uri = songMap["uri"] as! String
        self.artistName = songMap["artistName"] as! String
        self.songTitle = songMap["songTitle"] as! String
        self.albumURL = songMap["albumURL"] as! String
        self.songLength = UInt(songMap["songLength"] as! Int)
        self.likes = songMap["likes"] as! Int
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
