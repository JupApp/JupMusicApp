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
    var settings: Settings = Settings(queueOpen: true, hostEditingOn: false, selfLikingOn: true) {
        didSet {
            if !isHost { settingsVC?.updateSettings(true) }
        }
    }
    var participants: [String] = []
    var participantIDsToUsernames: [String: String] = [:]
    
    lazy var datasource =
        SongDataSource(queueVC: self)
    
    let songLikeFailedAlert = UIAlertController(title: "Failed to like Song", message: nil, preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark
        searchVC = storyboard?.instantiateViewController(identifier: "SearchVC")
        searchVC!.hostPlatform = platform
        
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
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.alwaysBounceVertical = false

        var snap = NSDiffableDataSourceSnapshot<String, QueueSongItem>()
        snap.appendSections(["Queue"])
        datasource.apply(snap, animatingDifferences: false)

        self.nowPlayingAlbum.image = UIImage(named: "placeholderfinal")
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
        
        //Background
        backgroundImageView = UIImageView()
        self.tableView.backgroundView = backgroundImageView
        backgroundImageView.frame = self.tableView.bounds
        
        let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        backgroundImageView.addSubview(backgroundBlurView)
        backgroundBlurView.frame = self.tableView.bounds
        
        //Makes Album Artwork corners rounded
        //nowPlayingAlbum.layer.masksToBounds = true
        //nowPlayingAlbum.layer.cornerRadius = 10
        //Shadow behind main album artwork
//        shadowView.layer.masksToBounds = false
//        shadowView.layer.shadowRadius = 10
//        shadowView.layer.shadowColor = UIColor.systemBackground.cgColor
//        shadowView.layer.shadowOpacity = 0.6
//        shadowView.layer.shadowOffset = CGSize.zero
//        shadowView.layer.shadowPath = UIBezierPath(roundedRect: nowPlayingAlbum.bounds, cornerRadius: 10).cgPath
        
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
        var image = self.nowPlayingAlbum.image
        if mpDelegate.currentSong == nil {
            image = UIImage()
        }

        for vc in navigationController?.viewControllers ?? [] {
            guard let propagator = vc as? BackgroundImagePropagator else {
                continue
            }
            propagator.backgroundImageView.image = image
        }
    }

}

extension QueueVC: UITableViewDragDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let item = datasource.itemIdentifier(for: indexPath) else {
            return []
        }
        guard isHost && settings.hostEditingOn else {
            return []
        }
        let itemProvider = NSItemProvider(object: item.uri as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item

        return [dragItem]
    }
    
}

extension QueueVC: UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {

    }
    
}

class SongDataSource: UITableViewDiffableDataSource<String, QueueSongItem> {
    var queueVC: QueueVC
    
    init(queueVC: QueueVC) {
        self.queueVC = queueVC
        super.init(tableView: queueVC.tableView) { tv, ip, s in
            let cell = tv.dequeueReusableCell(withIdentifier: "SongCell", for: ip) as? SongCell
            var updatedS = s
            if ip.row < queueVC.mpDelegate.queue.count {
                let songURI: String = queueVC.mpDelegate.queue[ip.row]
                let songItem: SongItem = queueVC.mpDelegate.songMap[songURI]!
                updatedS = QueueSongItem(songItem)
            }
            cell?.albumArtwork.image = updatedS.albumArtwork
            cell?.likeCountLabel.text = "\(updatedS.likes.count)"

            cell?.artistLabel.text = updatedS.artist
            cell?.artistLabel.textColor = .none
            cell?.contributorLabel.text = queueVC.participantIDsToUsernames[updatedS.contributor]!
            cell?.likeCountLabel.layer.masksToBounds = true
            cell?.likeCountLabel.layer.cornerRadius = 8
            if updatedS.likes.count == 0 {
                cell?.likeCountLabel.isHidden = true
            } else {
                cell?.likeCountLabel.isHidden = false
            }

            let uniqueID = UIDevice.current.identifierForVendor!.uuidString

            if updatedS.likes.contains(uniqueID) {
                cell?.likeButton.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            } else {
                cell?.likeButton.imageView?.transform = .identity
            }
                
            if (!queueVC.settings.selfLikingOn && updatedS.contributor == uniqueID) || queueVC.settings.hostEditingOn {
                    cell?.likeButton.isEnabled = false
                    cell?.likeButton.alpha = 0.5
                } else {
                    cell?.likeButton.isEnabled = true
                    cell?.likeButton.alpha = 1.0
                }
                cell?.completionHandler = {
                    let addlike: Bool = !updatedS.likes.contains(uniqueID)
                    queueVC.mpDelegate.likeSong(updatedS.uri, addlike, uniqueID)
                }
                cell?.titleLabel.text = updatedS.title
                //cell?.albumArtwork.layer.cornerRadius = 8
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return queueVC.isHost && queueVC.settings.hostEditingOn
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let uniqueID = UIDevice.current.identifierForVendor!.uuidString
        let songToEdit: SongItem = queueVC.mpDelegate.songMap[queueVC.mpDelegate.queue[indexPath.row]]!
        return queueVC.isHost || songToEdit.contributor == uniqueID
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        queueVC.mpDelegate.moveSong(sourceIndexPath.row, destinationIndexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let songURI: String = queueVC.mpDelegate.queue[indexPath.row]
            queueVC.mpDelegate.deleteSong(songURI)
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
    var likes: Set<String>
    var timeAdded: Date

    func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }
    
    init(title: String, artist: String, uri: String, albumArtwork: UIImage, contributor: String, likes: Set<String>, timeAdded: Date) {
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
    
