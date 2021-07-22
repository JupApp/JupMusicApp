//
//  QueueVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/6/20.
//
import SideMenu
import UIKit

class QueueVC: UITableViewController, BackgroundImagePropagator {
    

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var nowPlayingAlbum: UIImageView!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingProgress: UIProgressView!
    @IBOutlet weak var nowPlayingContributor: UILabel!
    
    var backgroundImageView: UIImageView!
    var searchVC: SearchVC?
    var participantMenuVC: ParticipantMenuVC?
    var settingsVC: QueueSettingsVC?
    
    var btDelegate: BTCommunicationDelegate!
    var mpDelegate: MediaPlayerDelegate!
    var isHost: Bool = false
    var platform: Platform = .APPLE_MUSIC
    var queueType: QueueType = .VOTING
    
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

            let username: String = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
            
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
                self.mpDelegate.likeSong(updatedS.uri, addlike) { e in
                    guard let error = e else {
                        // success!
                        if addlike {
                            self.mpDelegate.likedSongs.insert(updatedS.uri)
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
    
    let songLikeFailedAlert = UIAlertController(title: "Failed to like Song", message: nil, preferredStyle: .alert)
    
    override func viewDidLoad() {
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

        let nib = UINib(nibName: "SongCell", bundle: nil)

        tableView.register(nib, forCellReuseIdentifier: "SongCell")
        tableView.delegate = self
        tableView.dataSource = datasource
        tableView.allowsSelection = false
        tableView.isScrollEnabled = true

        var snap = NSDiffableDataSourceSnapshot<String, QueueSongItem>()
        snap.appendSections(["Queue"])
        datasource.apply(snap, animatingDifferences: false)

        self.nowPlayingAlbum.image = UIImage(named: "PlayButton")
        let tap = UITapGestureRecognizer(target: self, action: #selector(play))
        tap.cancelsTouchesInView = false
        self.nowPlayingAlbum.addGestureRecognizer(tap)
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(skip))
        swipe.cancelsTouchesInView = false
        swipe.direction = .right
        self.nowPlayingAlbum.addGestureRecognizer(swipe)

        self.nowPlayingAlbum.isMultipleTouchEnabled = true
        self.nowPlayingAlbum.isUserInteractionEnabled = true
        
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
        
        nowPlayingAlbum.layer.masksToBounds = true
        nowPlayingAlbum.layer.cornerRadius = 10
        
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowRadius = 10
        shadowView.layer.shadowColor = UIColor.systemBackground.cgColor
        shadowView.layer.shadowOpacity = 0.6
        shadowView.layer.shadowOffset = CGSize.zero
        shadowView.layer.shadowPath = UIBezierPath(roundedRect: shadowView.bounds, cornerRadius: 10).cgPath
        
        
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
    
    func returnToSettingsSegue(_ act:UIAlertAction){
        //clear playlist cache
        SpotifyUtilities.clearCache()
        AppleMusicUtilities.clearCache()
        mpDelegate.songTimer?.invalidate()
        performSegue(withIdentifier: "exitQueue", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "exitQueue" {
            btDelegate.breakConnections()
        } else if segue.identifier == "openParticipantsMenu" {
            participantMenuVC = segue.destination as? ParticipantMenuVC
            participantMenuVC?.parentVC = self
        } else if segue.identifier == "openSettings" {
            settingsVC = segue.destination as? QueueSettingsVC
            settingsVC?.queueVC = self
        }
    }
    
    @objc func didEnterBackground() {
        if mpDelegate.state == .PLAYING {
            mpDelegate.loadQueueIntoPlayer()
        }
    }
    
    @objc func didEnterForeground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mpDelegate.returnedToApp()
        }
    }
    
    @objc func willTerminate() {
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
            propagator.backgroundImageView.image = image
        }
    }
}

class SpotifyAppRemoteError: Error {}

struct QueueSongItem: Hashable {
    var title: String
    var artist: String
    var uri: String
    var albumArtwork: UIImage
    var contributor: String
    var likes: Int
    var timeAdded: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }
    
    init(title: String, artist: String, uri: String, albumArtwork: UIImage, contributor: String, likes: Int, timeAdded: Date) {
        self.title = title
        self.artist = artist
        self.uri = uri
        self.albumArtwork = albumArtwork
        self.contributor = contributor
        self.likes = likes
        self.timeAdded = timeAdded
    }
    
    init(_ songItem: SongItem) {
        self.title = songItem.songTitle
        self.artist = songItem.artistName
        self.uri = songItem.uri
        self.albumArtwork = songItem.albumArtwork ?? UIImage()
        self.contributor = songItem.contributor
        self.likes = songItem.likes
        self.timeAdded = songItem.timeAdded
    }
    
    static func ==(lhs: QueueSongItem, rhs: QueueSongItem) -> Bool {
        return lhs.uri == rhs.uri
    }
}

protocol BackgroundImagePropagator {
    var backgroundImageView: UIImageView! { get set }
}
    
