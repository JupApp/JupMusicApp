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
        participantTableView.register(ParticipantMenuCell.self, forCellReuseIdentifier: "ParticipantMenuCell")
        self.view.addSubview(participantTableView)
        participantTableView.frame = self.view.bounds
        let cellNib = UINib(nibName: "ParticipantMenuCell", bundle: nil)
        participantTableView.register(cellNib, forCellReuseIdentifier: "ParticipantMenuCell")
        participantTableView.backgroundColor = UIColor(red: 205/255, green: 230/255, blue: 231/255, alpha: 1)
        participantTableView.separatorStyle = .none
        
    //Code for TableView SideMenu
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("\n\n\n\n\n\n\n\n\n\nRows function got called\n\n\n\n\n\n\n\n\n\n\n")
        if section == 0{
            return 1
        }
        if section == 1{
            return 5
        }
    return section
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionName: String
        switch section {
            case 0:
                sectionName = NSLocalizedString("Host", comment: "Host")
            case 1:
                sectionName = NSLocalizedString("Participants", comment: "Participants")
            
            default:
                sectionName = ""
        }
        return sectionName
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(
                withIdentifier: "ParticipantMenuCell", for: indexPath) as? ParticipantMenuCell
        if cell == nil {
            cell = ParticipantMenuCell(style:.default, reuseIdentifier: "ParticipantMenuCell")
        }
        return cell!
    }
}

