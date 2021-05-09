//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//
import StoreKit
import UIKit

class SearchVC: UITableViewController, UISearchBarDelegate, SearchDelegate, BackgroundImagePropagator{


    @IBOutlet weak var musicSearchBar: UISearchBar!
//    var musicSearchBar: UISearchBar = UISearchBar()
    var searchPlatformSegmentedControl: UISegmentedControl = UISegmentedControl()
    
    var currentPlatform: Platform = .APPLE_MUSIC
    var backgroundImageView: UIImageView! = UIImageView()
    
    lazy var datasource =
            UITableViewDiffableDataSource<String, PlaylistItem>(tableView: tableView) { tv, ip, s in
        var cell = tv.dequeueReusableCell(withIdentifier: "PlaylistCell", for: ip) as! PlaylistCell
        cell.playlistName.text = s.name
        cell.playlistImage.image = UIImage(named: "DefaultArtwork")
        s.retrieveArtwork { image in
            DispatchQueue.main.async {
                cell.playlistImage.image = image ?? UIImage(named: "DefaultArtwork")
            }
        }
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        return cell
                
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        searchPlatformSegmentedControl.insertSegment(withTitle: "Apple Music", at: 0, animated: false)
        searchPlatformSegmentedControl.insertSegment(withTitle: "Spotify", at: 1, animated: false)
        searchPlatformSegmentedControl.selectedSegmentIndex = 0
        searchPlatformSegmentedControl.addTarget(self, action: #selector(platformTextfieldPlaceholder(sender:)), for: .valueChanged)
        musicSearchBar.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        // Handle TableView set up
        self.tableView.delegate = self
        self.tableView.allowsSelection = true
        self.tableView.dataSource = datasource
        self.tableView.register(UINib(nibName: "PlaylistCell", bundle: nil), forCellReuseIdentifier: "PlaylistCell")

        searchAMLibrary()
        
        self.tableView.backgroundView = backgroundImageView
        backgroundImageView.frame = self.tableView.bounds
        
        let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        backgroundImageView.addSubview(backgroundBlurView)
        backgroundBlurView.frame = self.tableView.bounds
        musicSearchBar.backgroundImage = UIImage()
        
        var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
        snap.appendSections(["Playlists"])
        snap.appendItems([])
        self.datasource.apply(snap, animatingDifferences: false)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let queueVC = navigationController?.viewControllers[0] as? QueueVC else {
            return
        }
        queueVC.propagateImage()
    }

    
    @objc func platformTextfieldPlaceholder(sender: UISegmentedControl){
        switch searchPlatformSegmentedControl.selectedSegmentIndex
            {
        case 0:
            musicSearchBar.placeholder = "Apple Music"
            musicSearchBar.tintColor = .lightGray
            currentPlatform = .APPLE_MUSIC
            
            // load playlist of AM if hasn't been done already
            searchAMLibrary()
            break;
        case 1:
            musicSearchBar.placeholder = "Spotify"
            musicSearchBar.tintColor = .lightGray
            currentPlatform = .SPOTIFY
            
            // load playlist of Spotify if hasn't been done already
            searchSpotifyLibrary()
            break;
        default:
            musicSearchBar.placeholder = "Apple Music"
            musicSearchBar.tintColor = .lightGray
            currentPlatform = .APPLE_MUSIC
            
            // load playlist of AM if hasn't been done already
            searchAMLibrary()
            break;
        }
    }
    
    @objc func dismissKeyboard() {
        musicSearchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard()
        
        guard let searchQuery = searchBar.text else {
            return
        }
        if searchQuery.isEmpty {
            return
        }
        // if segmented control set to AM, perform AM catalogue request, else Spotify
        if currentPlatform == .APPLE_MUSIC {
            let songListVC = SongListVC<AppleMusicSongItem>()

            searchAMCatalogue(searchQuery, songListVC)
            navigationController?.pushViewController(songListVC, animated: true)
        } else {
            let songListVC = SongListVC<SpotifySongItem>()

            searchSpotifyCatalogue(searchQuery, songListVC)
            navigationController?.pushViewController(songListVC, animated: true)
        }
        
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // user selected playlist, push SongListVC on stack
        let playlistID: String
        if currentPlatform == .APPLE_MUSIC {
            guard indexPath.row < AppleMusicUtilities.playlistIDs.count else {
                return
            }

            let songListVC = SongListVC<AppleMusicSongItem>()

            playlistID = AppleMusicUtilities.playlistIDs[indexPath.row]
            searchAMPlaylist(playlistID, songListVC)

            navigationController?.pushViewController(songListVC, animated: true)
        } else {
            guard indexPath.row < SpotifyUtilities.playlistIDs.count else {
                return
            }
            let songListVC = SongListVC<SpotifySongItem>()

            playlistID = SpotifyUtilities.playlistIDs[indexPath.row]
            searchSpotifyPlaylist(playlistID, songListVC)
            navigationController?.pushViewController(songListVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return searchPlatformSegmentedControl
    }
    
    /*
     ###########################################################################################
     ########                                                                           ########
     ########                   SEARCH DELEGATE FUNCTIONS BELOW                         ########
     ########                                                                           ########
     ###########################################################################################
     */
    
    func searchAMCatalogue(_ searchQuery: String, _ songListVC: SongListVC<AppleMusicSongItem>) {
        AppleMusicUtilities.searchCatalogue(searchQuery) { songItems in
            var snap = NSDiffableDataSourceSnapshot<String, AppleMusicSongItem>()
            snap.appendSections(["Songs"])
            snap.appendItems(songItems)
            DispatchQueue.main.async {
                songListVC.datasource.apply(snap, animatingDifferences: false)
            }
        }
    }
    
    func searchAMLibrary() {
        AppleMusicUtilities.searchPlaylists() {
            // populates results into tableview
            var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
            snap.appendSections(["Playlists"])
            snap.appendItems(AppleMusicUtilities.playlistIDs.map({ (id) -> PlaylistItem in
                AppleMusicUtilities.playlists[id]!
            }))
            self.datasource.apply(snap, animatingDifferences: false)
        }
    }
    
    func searchSpotifyCatalogue(_ searchQuery: String, _ songListVC: SongListVC<SpotifySongItem>) {
        SpotifyUtilities.searchCatalogue(searchQuery) { songItems in
            var snap = NSDiffableDataSourceSnapshot<String, SpotifySongItem>()
            snap.appendSections(["Songs"])
            snap.appendItems(songItems)
            DispatchQueue.main.async {
                songListVC.datasource.apply(snap, animatingDifferences: false)
            }
        }
    }
    
    func searchSpotifyLibrary() {
        SpotifyUtilities.searchPlaylists {
            // populates results into tableview
            var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
            snap.appendSections(["Playlists"])
            snap.appendItems(SpotifyUtilities.playlistIDs.map({ (id) -> PlaylistItem in
                SpotifyUtilities.playlists[id]!
            }))
            self.datasource.apply(snap, animatingDifferences: false)
        }
    }
    
    func searchSpotifyPlaylist(_ playlistID: String, _ songListVC: SongListVC<SpotifySongItem>) {
        SpotifyUtilities.getPlaylistData(playlistID) {
            var snap = NSDiffableDataSourceSnapshot<String, SpotifySongItem>()
            snap.appendSections(["Songs"])
            snap.appendItems(SpotifyUtilities.playlistContent[playlistID]!)
            DispatchQueue.main.async {
                songListVC.datasource.apply(snap, animatingDifferences: false)
            }
        }
    }
    
    func searchAMPlaylist(_ playlistID: String, _ songListVC: SongListVC<AppleMusicSongItem>) {
        AppleMusicUtilities.getPlaylistData(playlistID) {
            var snap = NSDiffableDataSourceSnapshot<String, AppleMusicSongItem>()
            snap.appendSections(["Songs"])
            snap.appendItems(AppleMusicUtilities.playlistContent[playlistID]!)
            DispatchQueue.main.async {
                songListVC.datasource.apply(snap, animatingDifferences: false)
            }
        }
    }


    
    
    
}
