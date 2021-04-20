//
//  AMMediaPlayer.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import MediaPlayer

class AppleMusicMediaPlayer: MediaPlayer {
    
    var player = MPMusicPlayerController.systemMusicPlayer
    init() {
        if self.player.playbackState == .playing {
            self.player.pause()
        }
        self.player.setQueue(with: [])
        self.player.repeatMode = .none
        self.player.shuffleMode = .off
    }
    
    func play() {
        if self.player.playbackState != .playing {
            self.player.play()
        }
    }
    
    func pause() {
        if self.player.playbackState != .paused {
            self.player.pause()
        }
    }
    
    func skip() {
        self.player.skipToNextItem()
    }
    
    func transitionNextSong(_ songItem: SongItem, completionHandler: @escaping (Error?) -> ()) {
        player.setQueue(with: [songItem.uri])
        player.prepareToPlay()
        player.repeatMode = .none
        skip()
        play()
        completionHandler(nil)
    }
    
    func loadEntireQueue(_ songItems: [SongItem], completionHandler: @escaping (Error?) -> ()) {
        let upNext = MPMusicPlayerStoreQueueDescriptor(storeIDs: songItems.map({ (songItem) -> String in
            songItem.uri
        }))
        self.player.prepend(upNext)
        self.player.repeatMode = .none
    }
    
    func getTimeInfo(completionHandler: @escaping (Double, Double) -> ()) {
        let songDuration: Double = self.player.nowPlayingItem!.playbackDuration.magnitude
        let timeLeft: Double = songDuration - self.player.currentPlaybackTime.magnitude
        completionHandler(timeLeft, songDuration)
    }
    
    func nowPlayingInfo(_ completionHandler: @escaping (String?, Bool) -> ()) {
        let playing: Bool = self.player.playbackState == .playing
        print("Playing: \(playing)")
        completionHandler(self.player.nowPlayingItem?.playbackStoreID, playing)
    }
    
}
