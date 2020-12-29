//
//  ParticipantMenuViewController.swift
//  Jup
//
//  Created by Zach Venanzi on 12/28/20.
//

import SideMenu
import UIKit

class ParticipantMenuViewController: SideMenuNavigationController, UITableViewDelegate, UITableViewDataSource {
    
    var participantTableView: UITableView = UITableView()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        participantTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
        
    var items = ["1","2","3","4"]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}


    
    

