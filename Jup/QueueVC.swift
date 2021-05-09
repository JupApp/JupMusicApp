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
    
    init(_ songItem: SongItem) {
        self.title = songItem.songTitle
        self.artist = songItem.artistName
        self.uri = songItem.uri
        self.albumArtwork = songItem.albumArtwork ?? UIImage()
        self.contributor = songItem.contributor
        self.likes = songItem.likes
    }
    
    static func ==(lhs: QueueSongItem, rhs: QueueSongItem) -> Bool {
        return lhs.uri == rhs.uri
    }
}

protocol BackgroundImagePropagator {
    var backgroundImageView: UIImageView! { get set }
}

class QueueVC: UITableViewController, BackgroundImagePropagator {
    

    @IBOutlet weak var nowPlayingAlbum: UIImageView!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingProgress: UIProgressView!
    @IBOutlet weak var nowPlayingContributor: UILabel!
    
    var backgroundImageView: UIImageView!
    var searchVC: SearchVC?
    
    var btDelegate: BTCommunicationDelegate!
    var mpDelegate: MediaPlayerDelegate!
    var isHost: Bool = false
    var platform: Platform = .APPLE_MUSIC
    var queueType: QueueType = .VOTING
    var participantMenu: ParticipantMenuViewController?
    
    var host: String = ""
    var participants: [String] = []
    
    lazy var datasource =
        UITableViewDiffableDataSource<String, QueueSongItem>(tableView: self.tableView) { tv, ip, s in
        var cell =
            tv.dequeueReusableCell(withIdentifier: "SongCell", for: ip) as? SongCell
            var updatedS = s
            if ip.row < self.mpDelegate.queue.count {
                let songURI: String = self.mpDelegate.queue[ip.row]
                let songItem: SongItem = self.mpDelegate.songMap[songURI]!
                updatedS = QueueSongItem(songItem)
            }
            cell?.albumArtwork.image = updatedS.albumArtwork
            cell?.likeCountLabel.text = "\(updatedS.likes)"

            cell?.artistLabel.text = updatedS.artist
            cell?.artistLabel.textColor = .none
            cell?.contributorLabel.text = updatedS.contributor
            cell?.likeCountLabel.layer.masksToBounds = true
            cell?.likeCountLabel.layer.cornerRadius = 8
            if updatedS.likes == 0 {
                cell?.likeCountLabel.isHidden = true
            } else {
                cell?.likeCountLabel.isHidden = false
            }

            let username: String = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
            
            if self.mpDelegate.likedSongs.contains(updatedS.uri) {
                cell?.likeButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell?.likeButton.imageView?.transform = .identity
            }
            
            if updatedS.contributor == username {
                cell?.likeButton.isEnabled = false
                cell?.likeButton.alpha = 0.5
            } else {
                cell?.likeButton.isEnabled = true
                cell?.likeButton.alpha = 1.0
            }
            cell?.completionHandler = {
                let addlike: Bool = !self.mpDelegate.likedSongs.contains(updatedS.uri)
                print("Like Song: \(addlike)")
                self.mpDelegate.likeSong(updatedS.uri, addlike) { e in
                    guard let error = e else {
                        // success!
                        if addlike {
                            self.mpDelegate.likedSongs.insert(updatedS.uri)
                            print("\n\n\nSuccessfully liked song:\n\n\n")

                        } else {
                            self.mpDelegate.likedSongs.remove(updatedS.uri)
                        }
                        return
                    }
                    /*
                     Show alert of error!
                     */
                    self.songLikeFailedAlert.message = "'\(updatedS.title)' could not be liked"
                    self.present(self.songLikeFailedAlert, animated: true)
                    return
                }
            }
            cell?.titleLabel.text = updatedS.title
            cell?.albumArtwork.layer.cornerRadius = 8
            
        return cell
                
    }
    
    let failedSpotifyConnectionAlert = UIAlertController(title: "Failed to connect to Spotify", message: "Please try again", preferredStyle: .alert)
    let songLikeFailedAlert = UIAlertController(title: "Failed to like Song", message: nil, preferredStyle: .alert)
    
    override func viewDidLoad() {
        print("View Did Load called")
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        searchVC = storyboard?.instantiateViewController(identifier: "SearchVC")

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
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(skip))
        swipe.cancelsTouchesInView = false
        swipe.direction = .right
        self.nowPlayingAlbum.addGestureRecognizer(swipe)

        self.nowPlayingAlbum.isMultipleTouchEnabled = true
        self.nowPlayingAlbum.isUserInteractionEnabled = true
        
        

        participantMenu = ParticipantMenuViewController(rootViewController: UIViewController())
        participantMenu?.leftSide = true
        SideMenuManager.default.leftMenuNavigationController = participantMenu
        participantMenu?.menuWidth = 200
        participantMenu?.parentVC = self

        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Try again", style: .default, handler: failedSpotifyConnectionAlert(_:)))
        failedSpotifyConnectionAlert.addAction(UIAlertAction(title: "Return to Queue Settings", style: .cancel, handler: returnToSettingsSegue))
        
        songLikeFailedAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))

        nowPlayingProgress.setProgress(0, animated: false)

        // initialize developer tokens for AM and Spotify
        do{try AppleMusicUtilities.setNewAMAccessToken(completionHandler: {_ in})}catch{}
        SpotifyUtilities.setNewSpotifyAccessToken(completionHandler: {_ in })
        
        backgroundImageView = UIImageView()
        self.tableView.backgroundView = backgroundImageView
        backgroundImageView.frame = self.tableView.bounds
        
        let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        backgroundImageView.addSubview(backgroundBlurView)
        backgroundBlurView.frame = self.tableView.bounds
    }
    
    @objc func play() {
        if mpDelegate.state == .PLAYING {
            mpDelegate.pause()
        } else {
            mpDelegate.play()
        }
    }
    
    @objc func skip() {
        mpDelegate.skip()
    }
    
    @IBAction func presentSearchVC(_ sender: Any) {
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
        mpDelegate.songTimer?.invalidate()
//        mpDelegate = nil
        print("segueing to settings")
        performSegue(withIdentifier: "exitQueue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "exitQueue" {
            print("breaking connections")
            btDelegate.breakConnections()
//            btDelegate = nil
        }
    }
    
    @objc func didEnterBackground() {
        print("App entering background")
        print(btDelegate == nil)
        print("MPDelegate is nil: \(mpDelegate == nil)")
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
        print("App will terminate")
        btDelegate.breakConnections()
    }
    
    func propagateImage() {
        let image = self.nowPlayingAlbum.image
        guard let _ = self.mpDelegate.currentSong else {
            return
        }
        for vc in navigationController?.viewControllers ?? [] {
            guard let propagator = vc as? BackgroundImagePropagator else {
                continue
            }
            print("Set image")
            propagator.backgroundImageView.image = image
        }
//        self.backgroundImageView.image = image
//        self.searchVC!.setAlbumImage(image)
    }
}
    
