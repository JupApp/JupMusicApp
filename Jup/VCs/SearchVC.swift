//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//

import UIKit

class SearchVC: UIViewController {
    
   // @IBOutlet weak var spotifyLibraryButton: UIButton!
    //@IBOutlet weak var appleMusicLibraryButton: UIButton!
    @IBOutlet weak var searhTableView: UITableView!
    @IBOutlet weak var musicSearchBar: UISearchBar!
    @IBOutlet weak var searchPlatformSegmentedControl: UISegmentedControl!
    
    var searchDelegate: SearchDelegate!
    var platform: Platform = .APPLE_MUSIC
    var isHost: Bool = false
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
       
//        spotifyLibraryButton.backgroundColor = UIColor(red: 205/255, green: 230/255, blue: 231/255, alpha: 1)
//        spotifyLibraryButton.layer.cornerRadius = 13
//        appleMusicLibraryButton.backgroundColor = UIColor(red: 205/255, green: 230/255, blue: 231/255, alpha: 1)
//        appleMusicLibraryButton.layer.cornerRadius = 13

        //this is for the placeholder switching
        if Platform.self == AppleMusicMediaPlayer.self{
            musicSearchBar.placeholder = "search Apple Music"
            return
        }
        if Platform.self == SpotifyMediaPlayer.self{
            musicSearchBar.placeholder = "search Spotify"
            return
        }
        
        //This makes the keyboard show up immediately after seque
        musicSearchBar.becomeFirstResponder()
        searchDelegate = SearchDelegate()
        searchDelegate.searchAMLibrary()
    }
        func indexChanged(sender: UISegmentedControl) {
                switch searchPlatformSegmentedControl.selectedSegmentIndex
                    {
                case 0:
                
                    musicSearchBar.placeholder = "Apple music"
                
                    //show popular view
                case 1:
                    musicSearchBar.placeholder = "Spotify"
                    //show history view
                default:
                    musicSearchBar.placeholder = "Apple music"

                    break;
                }
}
}
