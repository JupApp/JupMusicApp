//
//  MediaPlayerDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import MediaPlayer

protocol MediaPlayerDelegate {
    func play()
    
    func pause()
    
    func skip()
    
    func addSong()
    
    func likeSong()
    
    func updateQueueWithSnapshot()
}
