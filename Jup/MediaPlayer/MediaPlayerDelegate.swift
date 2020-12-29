//
//  MediaPlayerDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit

protocol MediaPlayerDelegate {
    
    var songTimer: Timer? { get }
    var mediaPlayer: MediaPlayer? { get }
    
    func play()
    
    func pause()
    
    func skip()
    
    func addSong()
    
    func likeSong()
    
    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot()
}
