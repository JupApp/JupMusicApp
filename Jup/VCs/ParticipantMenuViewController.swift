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
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.view.addSubview(participantTableView)
        participantTableView.frame = self.view.bounds
    }
        
    var items = ["1","2","3","4"]

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\n\n\n\n\n\n\n\n\n\nRows function got called\n\n\n\n\n\n\n\n\n\n\n")
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}


    
    

