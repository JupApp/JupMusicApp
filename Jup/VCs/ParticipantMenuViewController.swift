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
        self.presentationStyle = .viewSlideOutMenuPartialIn
        participantTableView.delegate = self
        participantTableView.dataSource = self
        participantTableView.register(ParticipantMenuCell.self, forCellReuseIdentifier: "ParticipantMenuCell")
        self.view.addSubview(participantTableView)
        participantTableView.frame = self.view.bounds
        let cellNib = UINib(nibName: "ParticipantMenuCell", bundle: nil)
        participantTableView.register(cellNib, forCellReuseIdentifier: "ParticipantMenuCell")
        //participantTableView.backgroundColor = UIColor(red: 205/255, green: 230/255, blue: 231/255, alpha: 1)
        participantTableView.separatorStyle = .none
        self.menuWidth = 200
        participantTableView.backgroundColor = UIColor(patternImage: UIImage(named: "Queue Background")!)
//        let blurEffect = UIBlurEffect(style: .dark)
//        let blurEffectView = UIVisualEffectView(effect: blurEffect)
//        blurEffectView.frame = view.bounds
//        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addSubview(blurEffectView)
//    //Code for TableView SideMenu
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
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = UILabel()
//        let sectionTitle = UILabel()
        switch section {
        case 0:
            print("\n\n\n\n\n\n\n\n POOP 0\n\n\n\n\n\n")

            sectionHeader.backgroundColor = UIColor.init(red: 233/255, green: 246/255, blue: 242/255, alpha: 1)
//            sectionHeader.text = "Host"
//            sectionHeader.textColor = .lightGray
//            sectionHeader.font = UIFont.systemFont(ofSize: 10)

        case 1:
            sectionHeader.backgroundColor = UIColor.init(red: 233/255, green: 246/255, blue: 242/255, alpha: 1)
//            sectionHeader.text = "Participant"
//            sectionHeader.textColor = .lightGray
//            sectionHeader.font = UIFont.systemFont(ofSize: 10)
//            sectionHeader.textAlignment = .left
//            sectionHeader.addSubview(sectionTitle)

        default:
            sectionHeader.backgroundColor = UIColor.init(red: 233/255, green: 246/255, blue: 242/255, alpha: 1)
        }
        return sectionHeader
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
