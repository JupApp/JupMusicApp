//
//  QueueVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/6/20.
//

import UIKit

class QueueVC: UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    
    @IBOutlet weak var albumBackground: UIImageView!
    
    @IBOutlet weak var nowPlayingAlbum: UIImageView!
    @IBOutlet weak var nowPlayingTitle: UILabel!
    @IBOutlet weak var nowPlayingArtist: UILabel!
    @IBOutlet weak var nowPlayingProgress: UIProgressView!
    @IBOutlet weak var queueTable: UITableView!
    @IBOutlet weak var leaveQueueButton: UIButton!
    
    var btDelegate: BTCommunicationDelegate!
    var mpDelegate: MediaPlayerDelegate!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "SongCell", bundle: nil)
        queueTable.register(nib, forCellReuseIdentifier: "SongCell")
        queueTable.delegate = self
        queueTable.dataSource = self
        
        //Zachs Alert Attempt
        let leaveQueueAlert = UIAlertController(title: "Leave the Queue", message: nil, preferredStyle: .alert)
        leaveQueueAlert.addAction(UIAlertAction(title: "Leave", style: .destructive, handler: nil))
        leaveQueueAlert.addAction(UIAlertAction(title: "Stay", style: .cancel, handler: nil))
    
    
       
        }

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
        




