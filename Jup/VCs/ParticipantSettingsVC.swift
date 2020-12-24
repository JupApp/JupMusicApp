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
        
        let requestedScopes: SPTScope = [.appRemoteControl, .userReadRecentlyPlayed, .userTopRead, .playlistReadPrivate, .playlistReadCollaborative, .userLibraryRead]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.sessionManager.session?.isExpired == true {
            appDelegate.sessionManager.initiateSession(with: requestedScopes, options: .default)
        }
    }

    

    

}
