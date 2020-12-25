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
       
    var searchDelegate: SearchDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This makes the keyboard show up immediately after seque
        musicSearchBar.becomeFirstResponder()
        searchDelegate = SearchDelegate()
        searchDelegate.searchAMLibrary()
    }

}

