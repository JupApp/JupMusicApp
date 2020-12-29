//
//  MediaPlayerDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit

enum State {
    case PLAYING
    case PAUSED
    case TRANSITIONING
    case NO_SONG_SET
}

protocol MediaPlayerDelegate {
    var parentVC: QueueVC { get }
    var songTimer: Timer? { get }
    var mediaPlayer: MediaPlayer? { get }
    var state: State { get set }
    
    func play()
    
    func pause()
    
    func skip()
    
    func addSong()
    
    func likeSong()
    
    func loadQueueIntoPlayer()

    func updateQueueWithSnapshot()
}
