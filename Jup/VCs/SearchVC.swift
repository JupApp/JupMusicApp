//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//
import StoreKit
import UIKit

struct PlaylistItem: Hashable {
    var playlistName: String
    var playlistID: String
    
    init(_ name: String, _ id: String) {
        self.playlistName = name
        self.playlistID = id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(playlistID)
    }
    
    static func ==(lhs: PlaylistItem, rhs: PlaylistItem) -> Bool {
               return lhs.playlistID == rhs.playlistID
    }
}

class SearchVC: UITableViewController, UISearchBarDelegate {
    
   // @IBOutlet weak var spotifyLibraryButton: UIButton!
    //@IBOutlet weak var appleMusicLibraryButton: UIButton!
    @IBOutlet weak var musicSearchBar: UISearchBar!
//    @IBOutlet weak var searchPlatformSegmentedControl: UISegmentedControl!
    var searchPlatformSegmentedControl: UISegmentedControl = UISegmentedControl()

    
    var searchDelegate: SearchDelegate?
    var currentPlatform: Platform = .APPLE_MUSIC
    var isHost: Bool = false
    var parentVC: QueueVC?
    
    lazy var datasource =
            UITableViewDiffableDataSource<String, PlaylistItem>(tableView: tableView) { tv, ip, s in
        var cell =
            tv.dequeueReusableCell(withIdentifier: "PlaylistCell", for: ip)
                cell.textLabel?.text = s.playlistName
        return cell
                
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //start refreshing token if necessary
        SpotifyUtilities.checkAuthorization {}
        
        searchPlatformSegmentedControl.insertSegment(withTitle: "Apple Music", at: 0, animated: false)
        searchPlatformSegmentedControl.insertSegment(withTitle: "Spotify", at: 1, animated: false)
        searchPlatformSegmentedControl.selectedSegmentIndex = 0
        searchPlatformSegmentedControl.addTarget(self, action: #selector(platformTextfieldPlaceholder(sender:)), for: .valueChanged)

        // Handle TableView set up
        self.tableView.delegate = self
        self.tableView.allowsSelection = true
        self.tableView.dataSource = datasource
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaylistCell")
        var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
        snap.appendSections(["Playlists"])
        datasource.apply(snap, animatingDifferences: false)
        
        musicSearchBar.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
                        
        // initialize developer tokens for AM and Spotify
        do{try searchDelegate?.setNewAMAccessToken(completionHandler: {})}catch{}
        searchDelegate?.setNewSpotifyAccessToken(completionHandler: {})
        
        // load playlist of appropriate platform
        if currentPlatform == .APPLE_MUSIC {
            searchDelegate?.searchAMLibrary()
        } else {
            searchDelegate?.searchSpotifyLibrary()
        }

    }
    
    @objc func platformTextfieldPlaceholder(sender: UISegmentedControl){
        switch searchPlatformSegmentedControl.selectedSegmentIndex
            {
        case 0:
            musicSearchBar.placeholder = "Apple Music"
            currentPlatform = .APPLE_MUSIC
            
            // load playlist of AM if hasn't been done already
            searchDelegate?.searchAMLibrary()

            // update diffable data source with user apple music 
            //show popular view
            break;
        case 1:
            musicSearchBar.placeholder = "Spotify"
            currentPlatform = .SPOTIFY
            
            // load playlist of Spotify if hasn't been done already
            searchDelegate?.searchSpotifyLibrary()
            
            //show history view
            break;
        default:
            musicSearchBar.placeholder = "Apple Music"
            currentPlatform = .APPLE_MUSIC
            
            // load playlist of AM if hasn't been done already
            searchDelegate?.searchAMLibrary()
            
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
            searchDelegate?.searchAMCatalogue(searchQuery)
        } else {
            searchDelegate?.searchSpotifyCatalogue(searchQuery)
        }
        
    }
    
    func loadAppleMusicPersonalPlaylists() {
        //check if user has correct authorization
        if SKCloudServiceController.authorizationStatus() == .notDetermined {
            SKCloudServiceController.requestAuthorization {(status:
                SKCloudServiceAuthorizationStatus) in
                switch status {
                case .authorized:
                    break
                default:
                    //
                    // alert user that they dont have Apple Music?
                    //
                    return
                }
            }
        } else if (SKCloudServiceController.authorizationStatus() != .authorized) {
            //
            // alert user that they dont have Apple Music?
            //
            return
        }
        // authorized at this point:
        searchDelegate?.searchAMLibrary()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // user selected playlist, push SongListVC on stack
        let playlistID: String

        if currentPlatform == .APPLE_MUSIC {
            guard indexPath.row < searchDelegate!.amLibrary.playlistIDs.count else {
                return
            }
            let songListVC = SongListVC<AppleMusicSongItem>()

            playlistID = searchDelegate!.amLibrary.playlistIDs[indexPath.row]
            searchDelegate?.amLibrary.getPlaylistData(playlistID, searchDelegate!.amDevToken!, searchDelegate!.amUserToken!) {
                var snap = NSDiffableDataSourceSnapshot<String, AppleMusicSongItem>()
                snap.appendSections(["Songs"])
                snap.appendItems(self.searchDelegate!.amLibrary.playlistContent[playlistID]!)
                DispatchQueue.main.async {
                    songListVC.datasource.apply(snap, animatingDifferences: false)
                }
            }
            navigationController?.pushViewController(songListVC, animated: true)

        } else {
            guard indexPath.row < searchDelegate!.spotifyLibrary.playlistIDs.count else {
                return
            }
            let songListVC = SongListVC<SpotifySongItem>()

            playlistID = searchDelegate!.spotifyLibrary.playlistIDs[indexPath.row]
            searchDelegate?.spotifyLibrary.getPlaylistData(playlistID, "", "") {
                var snap = NSDiffableDataSourceSnapshot<String, SpotifySongItem>()
                snap.appendSections(["Songs"])
                snap.appendItems(self.searchDelegate!.spotifyLibrary.playlistContent[playlistID]!)
                DispatchQueue.main.async {
                    songListVC.datasource.apply(snap, animatingDifferences: false)
                }
            }
            navigationController?.pushViewController(songListVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return searchPlatformSegmentedControl
    }
    
    
    
    
}
