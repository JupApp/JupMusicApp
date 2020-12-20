//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//

import UIKit

class SearchVC: UIViewController{
    
    @IBOutlet weak var SpotifyLibraryButton: UIButton!
    @IBOutlet weak var AppleMusicLibraryButton: UIButton!
    @IBOutlet weak var SearhTableView: UITableView!
    @IBOutlet weak var musicSearchBar: UISearchBar!
       
    var searchDelegate: SearchDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This makes the keyboard show up immediately after seque
        musicSearchBar.becomeFirstResponder()
        
    }

}

