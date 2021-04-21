//
//  Platform.swift
//  Jup
//
//  Created by Nick Venanzi on 12/24/20.
//

enum Platform: Int {
    case APPLE_MUSIC = 0
    case SPOTIFY = 1
    
    mutating func toggle() {
        if self == .APPLE_MUSIC {
            self = .SPOTIFY
        } else {
            self = .APPLE_MUSIC
        }
    }
}
