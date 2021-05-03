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
    var parentVC: QueueVC?
    
    let exitAlert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)

    override func viewDidLoad() {
        
        let background = UIImage(named: "Queue Background")
        var imageView : UIImageView!
                imageView = UIImageView(frame: view.bounds)
                imageView.contentMode =  UIView.ContentMode.scaleAspectFill
                imageView.clipsToBounds = true
                imageView.image = background
                imageView.center = view.center
                view.addSubview(imageView)
        
        
        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        
        
        super.viewDidLoad()
        self.presentationStyle = .viewSlideOutMenuPartialIn
        participantTableView.delegate = self
        participantTableView.dataSource = self
        self.view.addSubview(participantTableView)
        //participantTableView.frame = self.view.bounds
        participantTableView.register(UINib(nibName: "ParticipantMenuCell", bundle: nil), forCellReuseIdentifier: "ParticipantMenuCell")
        //participantTableView.backgroundColor = UIColor(red: 205/255, green: 230/255, blue: 231/255, alpha: 1)
        participantTableView.separatorStyle = .singleLine
        self.menuWidth = 200
        participantTableView.frame = CGRect(x: 0, y: 40, width: 200, height: view.frame.height-100)
        participantTableView.backgroundColor = UIColor(patternImage: UIImage(named: "BlurRectangle")!)
        participantTableView.backgroundColor = UIColor.clear
        
        let exitQueueButton = UIButton(frame: CGRect(x: 0, y: view.frame.maxY-58, width: 200, height: 58))
        exitQueueButton.backgroundColor = UIColor.init(red: 233/255, green: 246/255, blue: 242/255, alpha: 0.10)
        exitQueueButton.setTitle("Exit Queue", for: .normal)
        exitQueueButton.titleLabel?.textAlignment = .right
        exitQueueButton.setTitleColor(UIColor.lightGray, for: .normal)
        exitQueueButton.titleLabel?.font = .boldSystemFont(ofSize: 24)
        exitQueueButton.layer.cornerRadius = 10
        self.view.addSubview(exitQueueButton)
        exitQueueButton.addTarget(self, action: #selector(exitButtonPressed), for: .touchUpInside)
    //Code for TableView SideMenu
        exitAlert.addAction(UIAlertAction(title: "Leave the Queue", style: .destructive, handler: {
            (action) in
            self.dismiss(animated: false, completion: {
                self.parentVC?.returnToSettingsSegue(action)
            })
        }))
        exitAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
   
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0{
            return 1
        }
        if section == 1{
            return parentVC?.participants.count ?? 0
        }
        return 0
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 3
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHeader = UILabel()
        let color: UIColor = UIColor(red: 233/255, green: 246/255, blue: 242/255, alpha: 1)
        sectionHeader.backgroundColor = color
////        let sectionTitle = UILabel()
//        switch section {
//        case 0:
////            sectionHeader.text = "Host"
////            sectionHeader.textColor = .lightGray
////            sectionHeader.font = UIFont.systemFont(ofSize: 10)
//        case 1:
////            sectionHeader.text = "Participant"
////            sectionHeader.textColor = .lightGray
////            sectionHeader.font = UIFont.systemFont(ofSize: 10)
////            sectionHeader.textAlignment = .left
////            sectionHeader.addSubview(sectionTitle)
//        default:
////            sectionHeader.backgroundColor = color
//        }
        return sectionHeader
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
                withIdentifier: "ParticipantMenuCell", for: indexPath) as! ParticipantMenuCell
        let userName: String = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
        let name: String
        if indexPath.section == 0 {
            name = parentVC!.host
            cell.participantNameLabel.text = name + (name == userName ? " ⭑":"")
            print("Text on cell \(indexPath.row): \(cell.participantNameLabel.text)")
        } else {
            name = parentVC!.participants[indexPath.row]
            cell.participantNameLabel.text = name + (name == userName ? " ⭑":"")
            print("Text on cell \(indexPath.row): \(cell.participantNameLabel.text)")

        }
        return cell
    }
    
    @objc func exitButtonPressed() {
        self.present(exitAlert, animated: true)
    }
    
}
