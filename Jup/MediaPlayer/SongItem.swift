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
    
    func retrieveArtwork(completionHandler: @escaping (_ image: UIImage) -> ())
}
