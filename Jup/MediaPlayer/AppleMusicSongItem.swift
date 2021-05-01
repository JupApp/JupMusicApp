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
    var likes: Int
    var added: Bool = false
    var platform: Platform = .APPLE_MUSIC
    var contributor: String

    var albumArtwork: UIImage?
    
    convenience init(id: String, artist: String, song: String, albumURL: String, length: UInt, contributor: String) {
        self.init(id: id, artist: artist, song: song, albumURL: albumURL, length: length, likes: 0, contributor: contributor)
    }
    
    required init(id: String, artist: String, song: String, albumURL: String, length: UInt, likes: Int, contributor: String) {
        self.uri = id
        self.artistName = artist
        self.songTitle = song
        self.albumURL = albumURL
        self.songLength = length
        self.likes = likes
        self.contributor = contributor
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
    
    func copy() -> SongItem {
        return AppleMusicSongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes, contributor: contributor)
    }
    
}
