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
    var title: String?
    var subtitle: String?
    var identifier: String { return uri }
    var isAvailableOffline: Bool = false
    var isPlayable: Bool = true
    var isContainer: Bool = false
    var children: [SPTAppRemoteContentItem]?
    var imageIdentifier: String { return albumURL }
    
    
    var uri: String
    var artistName: String
    var songTitle: String
    var albumURL: String
    var songLength: UInt
    
    init(uri: String, artist: String, song: String, albumURL: String, length: UInt) {
        self.uri = uri
        self.artistName = artist
        self.songTitle = song
        self.albumURL = albumURL
        self.songLength = length
    }
    
    func retrieveArtwork(completionHandler: @escaping (UIImage) -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.appRemote.imageAPI?.fetchImage(forItem: AlbumURLString(albumURL), with: CGSize(width: 40, height: 40), callback: { (success, error) in
            if let image = success as? UIImage {
                completionHandler(image)
            } else {
                completionHandler(UIImage())
            }
        })
    }
    
    
}
