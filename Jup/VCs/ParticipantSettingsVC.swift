//
//  ParticipantSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit

class ParticipantSettingsVC: UIViewController {
    
    var tableView: UITableView!
   
    @IBOutlet weak var connectToSpotifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectToSpotifyButton.addTarget(self, action: #selector(connectToSpotify(_:)), for: .touchUpInside)
        
    }
    
    @objc func connectToSpotify(_ sender: UIButton) {
        let storage = UserDefaults.standard
        
        if let name = storage.string(forKey: "Name") {
            if name == "Garbage" {
                sender.setTitle("POOP", for: .normal)
            }
        } else {
            print("Unsuccessful retrieval, setting name now...")
            storage.set("Garbage", forKey: "Name")
        }
    }
    
}
