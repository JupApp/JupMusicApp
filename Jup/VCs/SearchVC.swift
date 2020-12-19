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
        
        musicSearch.becomeFirstResponder()
        
        }
        
    
    @IBOutlet weak var musicSearch: UISearchBar!
       
}

