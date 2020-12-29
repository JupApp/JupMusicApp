//
//  ParticipantMenuViewController.swift
//  Jup
//
//  Created by Zach Venanzi on 12/28/20.
//

import SideMenu
import UIKit

class ParticipantMenuViewController: SideMenuNavigationController{
    
    var participantMenu: SideMenuNavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        participantMenu = SideMenuNavigationController(rootViewController: ParticipantMenuTable())
    }
    class ParticipantMenuTable: UITableViewController{
    
        var items = ["1","2","3","4"]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        }
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return items.count
        }
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = items[indexPath.row]
        return cell
        
        }
    }
            
}

    
    
//    var participantTableView: UITableView!
//
//    let hostCell = "Host"
//    let particpantCell = "Participant"
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        participantTableView.delegate = self
//        participantTableView.dataSource = self
//
//        self.view.addSubview(participantTableView)
//        participantTableView.frame = self.view.bounds
//
//        //do these two lines for each nib you want to include in table view
//        let nib = UINib(nibName: "SongCell", bundle: nil)
//        participantTableView.register(nib, forCellReuseIdentifier: "SongCell")
//    }
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        <#code#>
//    }
//
   
//    self.tableView.register(
//        UINib(Nibname:SearchCell)
//        )
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        tableView.register("SearchCell", forCellReuseIdentifier:self.hostCell)
//        if indexPath.row == 0 {
//            let cell = Bundle.main.loadNibNamed("Search", owner: self, options: nil)
//            return cell
//        } else if indexPath.row == 1 {
//            let cell = Bundle.main.loadNibNamed("SongCell", owner: self, options: nil)
//            return cell
//        }
//
//
    
    
    

