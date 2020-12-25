//
//  MediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

protocol MediaPlayer {
    
    func play()
    
    func pause()
    
    func skip()
    
    func transitionNextSong(_ songItem: SongItem, completionHandler: @escaping (Error?) -> ())

    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ())
}
