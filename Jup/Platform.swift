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
    
    func rawValue() -> Int {
        if self == .APPLE_MUSIC {
            return 0
        } else {
            return 1
        }
    }
    
    static func rawValueToPlatform(_ num: Int) -> Platform {
        if num == 0 {
            return .APPLE_MUSIC
        } else if num == 1 {
            return .SPOTIFY
        }
        fatalError("Invalid argument: \(num)")
    }
    
    func printPlatform() {
        if self == .APPLE_MUSIC {
            print("Current platform: Apple Music")
        } else {
            print("Current platform: Spotify")
        }
    }
}
