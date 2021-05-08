//
//  PlaylistItem.swift
//  Jup
//
//  Created by Nick Venanzi on 5/7/21.
//

class PlaylistItem: Hashable {
    var name: String
    var id: String
    var url: String
    var image: UIImage?
    var platform: Platform
    
    init(_ name: String, _ id: String, _ url: String, _ platform: Platform) {
        self.name = name
        self.id = id
        self.url = url
        self.platform = platform
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func ==(lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
               return lhs.id == rhs.id
    }
    
    func retrieveArtwork(_ completionHandler: @escaping (_ image: UIImage?) -> ()) {
        if let _ = image {
            completionHandler(image!)
            return
        }
        guard let url: URL = URL(string: url) else {
            /*
             Here is where we need to build a collage
             */
            if platform == .APPLE_MUSIC {
                AppleMusicUtilities.getPlaylistData(id) {
                    var songs = AppleMusicUtilities.playlistContent[self.id]!
                    if songs.count > 4 {
                        songs = [AppleMusicSongItem](songs[0...3])
                    }
                    Utilities.constructAlbumCollage(songs) { image in
                        self.image = image
                        completionHandler(image)
                    }
                }
            } else {
                SpotifyUtilities.getPlaylistData(id) {
                    var songs = SpotifyUtilities.playlistContent[self.id]!
                    if songs.count > 4 {
                        songs = [SpotifySongItem](songs[0...3])
                    }
                    Utilities.constructAlbumCollage(songs) { image in
                        self.image = image
                        completionHandler(image)
                    }
                }
            }
            return
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completionHandler(nil);
                return
            }
            DispatchQueue.main.async {
                self.image = UIImage(data: data)
                completionHandler(self.image)
            }
        }
        task.resume()
    }
}

