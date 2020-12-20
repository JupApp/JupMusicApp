//
//  SearchVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/9/20.
//

import UIKit

class SearchVC: UIViewController{
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This makes the keyboard show up immediately after seque
        musicSearch.becomeFirstResponder()
        
    }
    @IBOutlet weak var SpotifyLibraryBut: UIButton!
    @IBOutlet weak var AppleMusicLibraryBut: UIButton!
    @IBOutlet weak var SearhTableView: UITableView!
    @IBOutlet weak var musicSearch: UISearchBar!
       
}

