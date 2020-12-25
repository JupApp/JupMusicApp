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
            mediaPlayer = AppleMusicMediaPlayer()
            
        } else if platform == .SPOTIFY {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.connectToSpotify()
            guard let expired = appDelegate.sessionManager.session?.isExpired else {
                return nil
            }
            if expired {
                return nil
            }
            
            appDelegate.connectSpotifyAppRemote()
            if !appDelegate.appRemote.isConnected {
                return nil
            }
            
            var hasPremium: Bool = false
            appDelegate.appRemote.userAPI?.fetchCapabilities(callback: { (result, error) in
                guard let capability = result as? SPTAppRemoteUserCapabilities else {
                    return
                }
                if capability.canPlayOnDemand {
                    hasPremium = true
                }
            })
            if !hasPremium { return nil }
            guard let player = appDelegate.appRemote.playerAPI else {
                return nil
            }
            mediaPlayer = SpotifyMediaPlayer(player)
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
