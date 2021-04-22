//
//  ParticipantSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit


class ParticipantSettingsVC: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var displayNameTextField: UITextField!
    
    let btDelegate: BTParticipantDelegate = BTParticipantDelegate()
        
    let usernameAlert = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
        
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btDelegate.participantSettingsVC = self
        
        //joinQueueButton.layer.cornerRadius = 8
        displayNameTextField.layer.cornerRadius = 5
        var placeHolderText: String = "username"
        if let lastUsedUsername = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) {
            if lastUsedUsername != "" {
                placeHolderText = lastUsedUsername
            }
        }
        
        tableView.register(UINib(nibName: "JoinableQueueCell", bundle: nil), forCellReuseIdentifier: "JoinHostCell")

        displayNameTextField.delegate = self
        displayNameTextField.attributedPlaceholder = NSAttributedString(string: placeHolderText,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        //joinQueueButton.addTarget(self, action: #selector(joinButtonPressed), for: .touchUpInside)
    
        usernameAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.isScrollEnabled = true    }
    
    @objc func joinButtonPressed() {
        //
        // if no queue selected to join
        // add alert
        //
        if displayNameTextField.text == nil || displayNameTextField.text == "" {
            guard let stored_val = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) else {
                present(usernameAlert, animated: true)
                return
            }
            guard stored_val != "" else {
                present(usernameAlert, animated: true)
                return
            }
            performSegue(withIdentifier: "participantToQueue", sender: nil)
            return
        }
        let currentUserName = displayNameTextField.text!
        UserDefaults.standard.set(currentUserName, forKey: QueueSettingsVC.usernameKey)
        self.performSegue(withIdentifier: "participantToQueue", sender: nil)
        return
    }
    
//    @IBSegueAction func segueToQueue(_ coder: NSCoder) -> QueueVC? {
//        let queueVC = QueueVC(coder: coder)
//        queueVC?.isHost = false
//        // TO-DO gather data from selected queue
//        queueVC?.platform = .APPLE_MUSIC
//        return queueVC
//    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "segueToParticipantQueue" else {
            return
        }
        
        let navController = segue.destination as! UINavigationController
        let queueVC = navController.viewControllers[0] as! QueueVC
        queueVC.isHost = false
        queueVC.platform = Platform(rawValue: btDelegate.discoveredQueueInfo[btDelegate.hostPeripheral!]!["platform"] as! Int)!
        btDelegate.queueVC = queueVC
        queueVC.btDelegate = btDelegate
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinHostCell") as! joinableQueueCell
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "JoinHostCell")
        if indexPath.row < btDelegate.discoveredQueues.count {
            let peripheral = btDelegate.discoveredQueues[indexPath.row]
            let queueInfo = btDelegate.discoveredQueueInfo[peripheral]!
            
            let participants = try! btDelegate.decoder.decode(ParticipantList.self, from: queueInfo["Participants"] as! Data)
            
            cell.queueNameLabel.text = participants.hostUsername
            let _ = Platform(rawValue: queueInfo["Platform"] as! Int) == .APPLE_MUSIC ? "Apple Music" : "Spotify"
            cell.buttonClicked = {
                self.btDelegate.connectToQueue(peripheral)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "joinQueue", sender: nil)
                }
            }
        }
        cell.queueNameLabel.textColor = .darkGray
//        cell.detailTextLabel?.textColor = .darkGray
        cell.backgroundColor = UIColor(red: 229/255, green: 246/255, blue: 242/255, alpha: 1)
        
        return cell
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btDelegate.discoveredQueues.count
    }
}





