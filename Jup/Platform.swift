//
//  Platform.swift
//  Jup
//
//  Created by Nick Venanzi on 12/24/20.
//

enum Platform {
    case APPLE_MUSIC
    case SPOTIFY
    
    mutating func toggle() {
        if self == .APPLE_MUSIC {
            self = .SPOTIFY
        } else {
            self = .APPLE_MUSIC
        }
    }
    
    func printPlatform() {
        if self == .APPLE_MUSIC {
            print("Current platform: Apple Music")
        } else {
            print("Current platform: Spotify")
        }
    }
}
