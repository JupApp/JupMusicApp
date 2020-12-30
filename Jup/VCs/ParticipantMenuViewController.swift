//
//  ParticipantMenuViewController.swift
//  Jup
//
//  Created by Zach Venanzi on 12/28/20.
//

import SideMenu
import UIKit

class ParticipantMenuViewController: SideMenuNavigationController, UITableViewDelegate, UITableViewDataSource{
    
    var participantTableView: UITableView = UITableView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(SearchCell.self, forCellReuseIdentifier: "SearchCell")
        self.view.addSubview(participantTableView)
        participantTableView.frame = self.view.bounds
        let cellNib = UINib(nibName: "SearchCell", bundle: nil)
        participantTableView.register(cellNib, forCellReuseIdentifier: "SearchCell")
        participantTableView.
        

    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\n\n\n\n\n\n\n\n\n\nRows function got called\n\n\n\n\n\n\n\n\n\n\n")
        return 1
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(
                withIdentifier: "SearchCell", for: indexPath) as? SearchCell
        if cell == nil {
            cell = SearchCell(style:.default, reuseIdentifier: "SearchCell")
            cell?.SCSongAlbumArt.image = UIImage(named: "Join")
            cell?.SCSongArtist.text = "Bob th e"
            cell?.SCSongTitle.text = "asdasdasd"
            
        }
       
     //   let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        // cell.textLabel?.text = items[indexPath.row]
        return cell!
    }
}

    
    

