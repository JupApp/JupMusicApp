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
//
//        let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
//        let blurEffectView = UIVisualEffectView(effect: blurEffect)
//        blurEffectView.frame = view.bounds
//        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        view.addSubview(blurEffectView)
        
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ParticipantMenuCell")
        tableView.separatorStyle = .singleLine
//        tableView.backgroundColor = UIColor.clear
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
   
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        if section == 1 {
            return parentVC?.participants.count ?? 0
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ParticipantMenuCell", for: indexPath)
        let userName: String = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
        let name: String
        if indexPath.section == 0 {
            name = parentVC!.host
            print(name)
            cell.textLabel!.text = name + (name == userName ? " ⭑":"")
        } else {
            print("pooper")
            name = parentVC!.participants[indexPath.row]
            cell.textLabel!.text = name + (name == userName ? " ⭑":"")
        }
        return cell
    }
    
    @objc func exitButtonPressed() {
        self.present(exitAlert, animated: true)
    }
}
