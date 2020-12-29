//
//  ParticipantMPDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit

class ParticipantMPDelegate: MediaPlayerDelegate {
    var mediaPlayer: MediaPlayer?
    var parentVC: QueueVC
    var songTimer: Timer?
    var state: State
    
    init(_ parentVC: QueueVC) {
        self.parentVC = parentVC
        self.state = .NO_SONG_SET
    }
    //dont do anything if participant tries to play pause or skip
    func play() {}
    func pause() {}
    func skip() {}
    
    //should not encounter these functions as a participant
    func addSong() { fatalError() }
    func likeSong() { fatalError() }
    
    func updateQueueWithSnapshot() {
        // TO-DO
    }
    
    func loadQueueIntoPlayer() {
    }
    
    
}
