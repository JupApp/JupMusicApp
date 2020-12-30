//
//  QueueVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/6/20.
//
import SideMenu
import UIKit

class SpotifyAppRemoteError: Error {}

class QueueVC: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    
    
    @IBOutlet weak var albumBackground: UIImageView!
    @IBOutlet weak var nowPlayingAlbum: UIImageView!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingProgress: UIProgressView!
    @IBOutlet weak var queueTable: UITableView!
    @IBOutlet weak var leaveQueueButton: UIButton!
    
    var btDelegate: BTCommunicationDelegate!
    var mpDelegate: MediaPlayerDelegate!
    var isHost: Bool = false
    var platform: Platform = .APPLE_MUSIC
    var participantMenu: SideMenuNavigationController?
    
    let failedSpotifyConnectionAlert = UIAlertController(title: "Failed to connect to Spotify", message: "Please try again", preferredStyle: .alert)

    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        if isHost {
            mpDelegate = HostMPDelegate(platform, self)
            btDelegate = BTHostDelegate()
        } else {
            mpDelegate = ParticipantMPDelegate(self)
            btDelegate = BTParticipantDelegate()
        }
        
        
        let nib = UINib(nibName: "SongCell", bundle: nil)
        queueTable.register(nib, forCellReuseIdentifier: "SongCell")
        queueTable.delegate = self
        queueTable.dataSource = self
        
        self.nowPlayingAlbum.image = UIImage(named: "Join")
        let tap = UITapGestureRecognizer(target: self, action: #selector(play))
        self.nowPlayingAlbum.addGestureRecognizer(tap)
        self.nowPlayingAlbum.isMultipleTouchEnabled = true
        self.nowPlayingAlbum.isUserInteractionEnabled = true

        participantMenu = ParticipantMenuViewController(rootViewController: UIViewController())
        participantMenu?.leftSide = true
        SideMenuManager.default.leftMenuNavigationController = participantMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
        
        
        
        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: failedSpotifyConnectionAlert(_:)))
        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Return to Queue Settings", style: .cancel, handler: returnToSettingsSegue))

    }
    
    @objc func play() {
        mpDelegate.play()
    }

    @IBAction func participantMenuTapped(){
        present(participantMenu!, animated: true)
    
    }
    
    @IBSegueAction func segueToSearchVC(_ coder: NSCoder) -> SearchVC? {
        let searchVC = SearchVC(coder: coder)
        searchVC?.platform = platform
        searchVC?.isHost = isHost
        return searchVC
    }
    //FIX!!!!!!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1

    }
    
    //FIX!!!!!!
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let SongCell = queueTable.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        return SongCell
    }
    
    func failedSpotifyConnectionAlert(_ act:UIAlertAction){
        //Code for beep boop bopping
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        switch (mpDelegate.state) {
        case .NO_SONG_SET:
            //do nothing
            break
        case .PAUSED:
            appDelegate.appRemote.playerAPI?.getPlayerState({ (state, error) in
                var uri: String = ""
                var position: Int = 0
                if let _ = error {
                    print("error retrieving state, setting current song as uri and playback position to 0")
                } else {
                    uri = (state as! SPTAppRemotePlayerState).track.uri
                    position = (state as! SPTAppRemotePlayerState).playbackPosition
                }
                appDelegate.connect(uri, position) {
                    appDelegate.appRemote.playerAPI?.pause({ (_, _) in })
                }
            })
            break
        case .PLAYING:
            appDelegate.appRemote.playerAPI?.getPlayerState({ (state, error) in
                var uri: String = ""
                var position: Int = 0
                if let _ = error {
                    print("error retrieving state, setting current song as uri and playback position to 0")
                } else {
                    uri = (state as! SPTAppRemotePlayerState).track.uri
                    position = (state as! SPTAppRemotePlayerState).playbackPosition
                }
                appDelegate.connect(uri, position) {}
            })
            break
        case .TRANSITIONING:
            // if song up next, connect and then play up next song
            print("TO DO")
            // if no song up next, transition to .NO_SONG_SET, dont connect
        }
    }
    
    func returnToSettingsSegue(_ act:UIAlertAction){
        performSegue(withIdentifier: "segueToHome", sender: nil)
    }
        
    @objc func didEnterBackground() {
        print("App entering background")
        mpDelegate.loadQueueIntoPlayer()
    }
}

    
