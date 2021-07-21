//
//  SongListVC.swift
//  Jup
//
//  Created by Nick Venanzi on 4/12/21.
//

class SongListVC<T: SongItem>: UITableViewController, BackgroundImagePropagator where T: Hashable {
    
    var backgroundImageView: UIImageView! = UIImageView()
    var platform: Platform!
        
    lazy var datasource =
            UITableViewDiffableDataSource<String, T>(tableView: tableView) { tv, ip, s in
        var cell =
            tv.dequeueReusableCell(withIdentifier: "SearchSongCell", for: ip) as! SearchCell
                // temporarily set album artwork to default image
                cell.SCSongAlbumArt.image = UIImage(named: "DefaultArtwork")
                s.retrieveArtwork(completionHandler: { (artwork) in
                    cell.SCSongAlbumArt.image = artwork
                })
                cell.SCSongArtist.text = s.artistName
                cell.SCSongTitle.text = s.songTitle
                cell.SCSongAlbumArt.layer.cornerRadius = 6
                cell.SCSongAlbumArt.layer.masksToBounds = true
                cell.songItem = s
                cell.addSongButton.isHidden = s.added
                cell.completionHandler = { songItem in self.songAdded(songItem as! T) }
        return cell
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        // Handle TableView set up
        self.tableView.delegate = self
        self.tableView.dataSource = datasource
        self.tableView.register(UINib(nibName: "SearchCell", bundle: nil), forCellReuseIdentifier: "SearchSongCell")
        self.tableView.rowHeight = UITableView.automaticDimension;
        self.tableView.allowsSelection = false
        
        var snap = NSDiffableDataSourceSnapshot<String, T>()
        snap.appendSections(["Songs"])
        datasource.apply(snap, animatingDifferences: false)
        
        self.tableView.backgroundView = backgroundImageView
        backgroundImageView.frame = self.tableView.bounds
        
        let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        backgroundImageView.addSubview(backgroundBlurView)
        backgroundBlurView.frame = UIScreen.main.bounds
        
        tableView.backgroundColor = .clear
        self.view.backgroundColor = .clear
        self.view.tintColor = .clear
        self.tableView.tintColor = .clear

    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let queueVC = navigationController?.viewControllers[0] as? QueueVC else {
            return
        }
        queueVC.propagateImage()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func songAdded(_ songItem: T) {
        
        // update tableview
        var snap = self.datasource.snapshot()
        var updatedItem = songItem
        updatedItem.added = true
        snap.reloadItems([updatedItem])
        self.datasource.apply(snap, animatingDifferences: true)

        let queueVC: QueueVC = navigationController?.viewControllers[0] as! QueueVC

        // convert song if necessary
        if queueVC.platform == .APPLE_MUSIC && songItem is SpotifySongItem {
            AppleMusicUtilities.convertSpotifyToAppleMusic(songItem) { item in
                guard let convertedSongItem = item else {
                    /*
                     Could not convert song item, alert user.
                     In the future, we present a nice interface to help get the exact
                     desired song.
                     */
                    let songConversionAlert: UIAlertController = UIAlertController(title: "Failed to convert song from Apple Music to Spotify", message: "Song: '\(songItem.songTitle)' failed to convert.", preferredStyle: .alert)
                    songConversionAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    DispatchQueue.main.async {
                        self.present(songConversionAlert, animated: true)
                    }
                    return
                }
                self.addConvertedSong(convertedSongItem)
            }
        } else if queueVC.platform == .SPOTIFY && songItem is AppleMusicSongItem {
            SpotifyUtilities.convertAppleMusicToSpotify(songItem) { item in
                guard let convertedSongItem = item else {
                    /*
                     Could not convert song item, alert user.
                     In the future, we present a nice interface to help get the exact
                     desired song.
                     */
                    let songConversionAlert: UIAlertController = UIAlertController(title: "Failed to convert song from Spotify to Apple Music", message: "Song: '\(songItem.songTitle)' failed to convert.", preferredStyle: .alert)
                    songConversionAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    DispatchQueue.main.async {
                        self.present(songConversionAlert, animated: true)
                    }
                    return
                }
                self.addConvertedSong(convertedSongItem)
            }
        } else {
            self.addConvertedSong(songItem)
        }
        
    }
    
    func addConvertedSong(_ songItem: SongItem) {
        let queueVC: QueueVC = navigationController?.viewControllers[0] as! QueueVC

        queueVC.mpDelegate.addSong(songItem) { error in
            guard let _ = error else {
                /*
                 No error = success
                 */
                return
            }
            /*
             Failed to add song
             */
            let songFailedToAddAlert: UIAlertController = UIAlertController(title: "Request to Add Song Failed", message: "'\(songItem.songTitle)' might already be in the song queue. Wait for it to be played in order to add it back to the queue.", preferredStyle: .alert)
            songFailedToAddAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            DispatchQueue.main.async {
                self.present(songFailedToAddAlert, animated: true)
            }
        }
    }
}
