//
//  QueueVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/6/20.
//
import SideMenu
import UIKit

class SpotifyAppRemoteError: Error {}

struct SongTableItem: Hashable {
    var title: String
    var artist: String
    var uri: String
    var albumArtwork: UIImage
    var contributor: String
    var likes: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }
    
    static func ==(lhs: SongTableItem, rhs: SongTableItem) -> Bool {
               return lhs.uri == rhs.uri
    }
}

class QueueVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
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
    var participantMenu: ParticipantMenuViewController?
    
//    lazy var datasource =
//            UITableViewDiffableDataSource<String, SongTableItem>(tableView: queueTable) { tv, ip, s in
//        var cell =
//            tv.dequeueReusableCell(withIdentifier: "SongCell", for: ip) as? SongCell
//                cell?.albumArtwork.image = UIImage(named: "Join")
//        cell?.artistLabel.text = s.artist
//        cell?.contributorLabel.text = s.contributor
//        cell?.likeCountLabel.text = s.likes.description
//        cell?.titleLabel.text = s.title
//        print("\n\n\n\n\n\(s.artist)\n\n\n\n\n\n")
//        return cell
//    }

    
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
    

//        var snap = NSDiffableDataSourceSnapshot<String, SongTableItem>()
//        snap.appendSections(["Queue"])
//        snap.appendItems(songs.map({ (songItem) -> SongTableItem in
//            songItem.getSongTableItem()
//        }), toSection: "Queue")
////        snap.appendItems(songs.map({ (songItem) -> SongTableItem in
////            songItem.getSongTableItem()
////        }))
//        datasource.apply(snap, animatingDifferences: false)
        
        self.nowPlayingAlbum.image = UIImage(named: "placeHolderImage")
        let tap = UITapGestureRecognizer(target: self, action: #selector(play))
        self.nowPlayingAlbum.addGestureRecognizer(tap)
        self.nowPlayingAlbum.isMultipleTouchEnabled = true
        self.nowPlayingAlbum.isUserInteractionEnabled = true

        participantMenu = ParticipantMenuViewController(rootViewController: UIViewController())
        participantMenu?.leftSide = true
        SideMenuManager.default.leftMenuNavigationController = participantMenu
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)

        participantMenu?.menuWidth = 200
        participantMenu?.parentVC = self
        
    
        
        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: failedSpotifyConnectionAlert(_:)))
        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Return to Queue Settings", style: .cancel, handler: returnToSettingsSegue))

    }
    var songs: [SongItem] = [AppleMusicSongItem(id: "0", artist: "pooper0", song: "Poop0", albumURL: "www", length: 100), AppleMusicSongItem(id: "1", artist: "pooper1", song: "Poop1", albumURL: "www", length: 110), AppleMusicSongItem(id: "2", artist: "pooper2", song: "Poop2", albumURL: "www", length: 120), AppleMusicSongItem(id: "3", artist: "pooper3", song: "Poop3", albumURL: "www", length: 130)]
    var counter: Int = 0
    @objc func play() {
        mpDelegate.addSong(songs[counter])
        counter += 1
        print("\n\n\n\n\(queueTable.numberOfRows(inSection: 0))\n\n\n\n")
//        mpDelegate.play()
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
//    FIX!!!!!!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4

    }

    //FIX!!!!!!
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var songCell = tableView.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath) as? SongCell
        if songCell == nil {
            songCell = SongCell(style:.default, reuseIdentifier: "SongCell")
        }
        let songTableItem: SongTableItem = songs[indexPath.row].getSongTableItem()
        songCell?.albumArtwork.image = UIImage(named: "Join")
        songCell?.artistLabel.text = songTableItem.artist
        songCell?.contributorLabel.text = songTableItem.contributor
        songCell?.likeCountLabel.text = String(songTableItem.likes)
        songCell?.titleLabel.text = songTableItem.title
        return songCell!
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
        performSegue(withIdentifier: "segueToSettings", sender: nil)
    }
    
    @objc func didEnterBackground() {
        print("App entering background")
        mpDelegate.loadQueueIntoPlayer()
    }
}

    
