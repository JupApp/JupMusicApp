//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//
import StoreKit
import UIKit

class SearchVC: UIViewController, UISearchBarDelegate {
    
   // @IBOutlet weak var spotifyLibraryButton: UIButton!
    //@IBOutlet weak var appleMusicLibraryButton: UIButton!
    @IBOutlet weak var searhTableView: UITableView!
    @IBOutlet weak var musicSearchBar: UISearchBar!
    @IBOutlet weak var searchPlatformSegmentedControl: UISegmentedControl!
    
    var searchDelegate: SearchDelegate?
    var currentPlatform: Platform = .APPLE_MUSIC
    var isHost: Bool = false
    var parentVC: QueueVC?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        musicSearchBar.becomeFirstResponder()
        musicSearchBar.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
                
        searchPlatformSegmentedControl.addTarget(self, action: #selector(platformTextfieldPlaceholder(sender:)), for: .valueChanged)
        
        // initialize developer tokens for AM and Spotify
        do{try searchDelegate?.setNewAMAccessToken(completionHandler: {})}catch{}
        searchDelegate?.setNewSpotifyAccessToken(completionHandler: {})
        
        // load playlist of appropriate platform
        if currentPlatform == .APPLE_MUSIC {
            searchDelegate?.searchAMLibrary()
        } else {
            searchDelegate?.searchSpotifyLibrary()
        }
        
        /*
         DISPLAY THE CORRESPONDING PLAYLIST
         */

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
    
    
    
    
}
