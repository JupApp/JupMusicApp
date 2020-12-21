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
    
    func setUpNextSong()
    
    func loadEntireQueue()
}
