//
//  QueueVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/6/20.
//
import SideMenu
import UIKit

class SpotifyAppRemoteError: Error {}

class QueueVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    
    @IBOutlet weak var albumBackground: UIImageView!
    @IBOutlet weak var nowPlayingAlbum: UIImageView!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingProgress: UIProgressView!
    @IBOutlet weak var queueTable: UITableView!
    @IBOutlet weak var leaveQueueButton: UIButton!
    
    var btDelegate: BTCommunicationDelegate!
    var mpDelegate: MediaPlayerDelegate!
    var isHost: Bool = false
    var platform: Platform = .APPLE_MUSIC
    var participantMenu: SideMenuNavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        participantMenu = SideMenuNavigationController(rootViewController: UIViewController())
        if isHost {
            mpDelegate = HostMPDelegate(platform)
            btDelegate = BTHostDelegate()
        } else {
            mpDelegate = ParticipantMPDelegate()
            btDelegate = BTParticipantDelegate()
        }
        
        
        let nib = UINib(nibName: "SongCell", bundle: nil)
        queueTable.register(nib, forCellReuseIdentifier: "SongCell")
        queueTable.delegate = self
        queueTable.dataSource = self
        
        //Zachs Alert Attempt
        let leaveQueueAlert = UIAlertController(title: "Leave the Queue", message: nil, preferredStyle: .alert)
        leaveQueueAlert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: nil))
        leaveQueueAlert.addAction(UIAlertAction(title: "Stay", style: .cancel, handler: nil))
        participantMenu!.leftSide = true
        
        self.nowPlayingAlbum.image = UIImage(named: "Join")
        let tap = UITapGestureRecognizer(target: self, action: #selector(play))
        self.nowPlayingAlbum.addGestureRecognizer(tap)
        self.nowPlayingAlbum.isMultipleTouchEnabled = true
        self.nowPlayingAlbum.isUserInteractionEnabled = true
    
    }
    
    @objc func play() {
        mpDelegate.play()
    }
    @IBAction func participantMenuTapped(){
        present(participantMenu!, animated: true)
    }
    
    
    @IBSegueAction func segueToSearchVC(_ coder: NSCoder) -> SearchVC? {
        let searchVC = SearchVC(coder: coder)
        searchVC?.platform = platform
        searchVC?.isHost = isHost
        return searchVC
    }
    //FIX!!!!!!
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1

    }
    
    //FIX!!!!!!
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let SongCell = queueTable.dequeueReusableCell(withIdentifier: "SongCell", for: indexPath)
        return SongCell
    }
        




}
