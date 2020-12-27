//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//

import UIKit

class SearchVC: UIViewController{
    
    @IBOutlet weak var spotifyLibraryButton: UIButton!
    @IBOutlet weak var appleMusicLibraryButton: UIButton!
    @IBOutlet weak var searhTableView: UITableView!
    @IBOutlet weak var musicSearchBar: UISearchBar!
    @IBOutlet weak var spotifyButtonView: UIView!
    @IBOutlet weak var appleMusicButtonView: UIView!
    
    var searchDelegate: SearchDelegate!
    var platform: Platform = .APPLE_MUSIC
    var isHost: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spotifyButtonView = UIView()
        spotifyButtonView.layer.cornerRadius = 4.0
        let appleMusicButtonview = UIView()
        appleMusicButtonview.layer.cornerRadius = 4.0

        
        //This makes the keyboard show up immediately after seque
        musicSearchBar.becomeFirstResponder()
        searchDelegate = SearchDelegate()
        searchDelegate.searchAMLibrary()
    }

}

