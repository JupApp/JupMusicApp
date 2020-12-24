//
//  HostMPDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import UIKit
import MediaPlayer
import StoreKit


class HostMPDelegate: MediaPlayerDelegate {
    var mediaPlayer: MediaPlayer?
    
    init?(_ platform: Platform) {

        if platform == .APPLE_MUSIC {
            var AMAccess: Bool = false
            if SKCloudServiceController.authorizationStatus() == .notDetermined {
                SKCloudServiceController.requestAuthorization {(status:
                    SKCloudServiceAuthorizationStatus) in
                    switch status {
                    case .authorized: AMAccess = true
                    default: break
                    }
                }
            } else if (SKCloudServiceController.authorizationStatus() == .authorized) {
                AMAccess = true
            }
            
            // if no apple music access: failed to initialize
            if !AMAccess {
                return nil
            }
            
            mediaPlayer = AMMediaPlayer()
        }
    }
    
    var songTimer: Timer?
    
    func play() {
        
    }
    
    func pause() {
        
    }
    
    func skip() {
        
    }
    
    func addSong() {
        
    }
    
    func likeSong() {
        
    }
    
    func updateQueueWithSnapshot() {
        fatalError()
    }
    
    
}
