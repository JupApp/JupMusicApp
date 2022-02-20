//
//  ParticipantMenuViewController.swift
//  Jup
//
//  Created by Zach Venanzi on 12/28/20.
//

import SideMenu
import UIKit

class ParticipantMenuVC: UITableViewController {

    var parentVC: QueueVC?
    
    let exitAlert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)

    override func viewDidLoad() {
        overrideUserInterfaceStyle = .dark
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ParticipantMenuCell")
        tableView.separatorStyle = .singleLine
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parentVC?.participants.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ParticipantMenuCell", for: indexPath)
        let uniqueID: String = UIDevice.current.identifierForVendor!.uuidString
        let rowID: String = parentVC!.participants[indexPath.row]
        let name: String = parentVC!.participantIDsToUsernames[rowID]!
        //cell.textLabel!.text = name + (rowID == uniqueID ? " ⭑":"")
        cell.textLabel!.text = String(indexPath.row + 1) + ".  " + name
        cell.textLabel!.font = .boldSystemFont(ofSize: 30)
        return cell
    }
    
    @objc func exitButtonPressed() {
        self.present(exitAlert, animated: true)
    }
}
