//
//  QueueVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/6/20.
//
import SideMenu
import UIKit

class SpotifyAppRemoteError: Error {}

struct QueueSongItem: Hashable {
    var title: String
    var artist: String
    var uri: String
    var albumArtwork: UIImage
    var contributor: String
    var likes: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }
    
    init(title: String, artist: String, uri: String, albumArtwork: UIImage, contributor: String, likes: Int) {
        self.title = title
        self.artist = artist
        self.uri = uri
        self.albumArtwork = albumArtwork
        self.contributor = contributor
        self.likes = likes
    }
    
    static func ==(lhs: QueueSongItem, rhs: QueueSongItem) -> Bool {
               return lhs.uri == rhs.uri
    }
}

class QueueVC: UITableViewController {
    

    @IBOutlet weak var nowPlayingAlbum: UIImageView!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingProgress: UIProgressView!
    @IBOutlet weak var nowPlayingContributor: UILabel!
        
    
    var btDelegate: BTCommunicationDelegate!
    var mpDelegate: MediaPlayerDelegate!
    var isHost: Bool = false
    var platform: Platform = .APPLE_MUSIC
    var queueType: QueueType = .VOTING
    var participantMenu: ParticipantMenuViewController?
//    var searchVC: SearchVC?
    
    var host: String = ""
    var participants: [String] = []
    
    lazy var datasource =
        UITableViewDiffableDataSource<String, QueueSongItem>(tableView: self.tableView) { tv, ip, s in
        var cell =
            tv.dequeueReusableCell(withIdentifier: "SongCell", for: ip) as? SongCell
            if ip.row < self.mpDelegate.queue.count {
                let songURI: String = self.mpDelegate.queue[ip.row]
                cell?.albumArtwork.image = self.mpDelegate.songMap[songURI]!.albumArtwork
            } else {
                cell?.albumArtwork.image = s.albumArtwork
            }

            cell?.artistLabel.text = s.artist
            cell?.contributorLabel.text = s.contributor
            cell?.likeCountLabel.text = s.likes.description
            cell?.titleLabel.text = s.title
            cell?.albumArtwork.layer.cornerRadius = 8
            
        return cell
                
    }
    
    let failedSpotifyConnectionAlert = UIAlertController(title: "Failed to connect to Spotify", message: "Please try again", preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: UIApplication.willTerminateNotification, object: nil)

        if isHost {
            mpDelegate = HostMPDelegate(platform, self)
            btDelegate = BTHostDelegate(self)
        } else {
            mpDelegate = ParticipantMPDelegate(self)
        }
//        searchVC = storyboard?.instantiateViewController(identifier: "SearchVC")

        let nib = UINib(nibName: "SongCell", bundle: nil)

        tableView.register(nib, forCellReuseIdentifier: "SongCell")
        tableView.delegate = self
        tableView.dataSource = datasource
        tableView.allowsSelection = false
        tableView.isScrollEnabled = true


        var snap = NSDiffableDataSourceSnapshot<String, QueueSongItem>()
        snap.appendSections(["Queue"])
        datasource.apply(snap, animatingDifferences: false)

        self.nowPlayingAlbum.image = UIImage(named: "placeHolderImage")
        let tap = UITapGestureRecognizer(target: self, action: #selector(play))
        tap.cancelsTouchesInView = false
        self.nowPlayingAlbum.addGestureRecognizer(tap)

        self.nowPlayingAlbum.isMultipleTouchEnabled = true
        self.nowPlayingAlbum.isUserInteractionEnabled = true

        participantMenu = ParticipantMenuViewController(rootViewController: UIViewController())
        participantMenu?.leftSide = true
        SideMenuManager.default.leftMenuNavigationController = participantMenu
        participantMenu?.menuWidth = 200
        participantMenu?.parentVC = self

        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: failedSpotifyConnectionAlert(_:)))
        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Return to Queue Settings", style: .cancel, handler: returnToSettingsSegue))

        nowPlayingProgress.setProgress(0, animated: false)

        // initialize developer tokens for AM and Spotify
        do{try AppleMusicUtilities.setNewAMAccessToken(completionHandler: {_ in})}catch{}
        SpotifyUtilities.setNewSpotifyAccessToken(completionHandler: {_ in })
    }
    
    @objc func play() {
        if mpDelegate.state == .PLAYING {
            mpDelegate.pause()
        } else {
            mpDelegate.play()
        }
    }
    
    @IBAction func presentSearchVC(_ sender: Any) {
        let searchVC = storyboard?.instantiateViewController(identifier: "SearchVC")
        self.navigationController?.pushViewController(searchVC!, animated: true)
    }
    
    func failedSpotifyConnectionAlert(_ act: UIAlertAction){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        switch (mpDelegate.state) {
        case .NO_SONG_SET:
            //do nothing
            break
        case .PAUSED:
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
                appDelegate.connect(uri, position) { _ in 
                }
            })
            break
        case .TRANSITIONING:
            
            // if song up next, connect and then play up next song
            print("TO DO")
        }
    }
    
    @IBAction func participantMenuTapped() {
        present(participantMenu!, animated: true)
    }
    
    func returnToSettingsSegue(_ act:UIAlertAction){
        //clear playlist cache
        SpotifyUtilities.clearCache()
        AppleMusicUtilities.clearCache()
        
        performSegue(withIdentifier: "exitQueue", sender: nil)
    }
    
    @objc func didEnterBackground() {
        print("App entering background")
        if mpDelegate.state == .PLAYING {
            mpDelegate.loadQueueIntoPlayer()
        }
    }
    
    @objc func didEnterForeground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Async after 0.1 seconds")
            self.mpDelegate.returnedToApp()
        }
    }
    
    @objc func willTerminate() {
        btDelegate.breakConnections()
    }
}
    
