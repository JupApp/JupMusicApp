//
//  ParticipantSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit
import CoreBluetooth

class ParticipantSettingsVC: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var displayNameTextField: UITextField!
    
    let btDelegate: BTParticipantDelegate = BTParticipantDelegate()
        
    let usernameAlert = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
        
   
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .dark

        
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
    
    func joinButtonPressed() {
        if displayNameTextField.text == nil || displayNameTextField.text == "" {
            guard let stored_val = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) else {
                present(usernameAlert, animated: true)
                return
            }
            guard stored_val != "" else {
                present(usernameAlert, animated: true)
                return
            }
            self.performSegue(withIdentifier: "joinQueue", sender: nil)
            return
        }
        let currentUserName = displayNameTextField.text!
        UserDefaults.standard.set(currentUserName, forKey: QueueSettingsVC.usernameKey)
        self.performSegue(withIdentifier: "joinQueue", sender: nil)
        return
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "joinQueue" else {
            return
        }
        
        let navController = segue.destination as! UINavigationController
        let queueVC = navController.viewControllers[0] as! QueueVC
        queueVC.isHost = false
        
        queueVC.platform = btDelegate.discoveredQueueInfo[btDelegate.hostPeripheral!]!.platform
        
        btDelegate.queueVC = queueVC
        queueVC.btDelegate = btDelegate
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinHostCell") as! JoinableQueueCell

        if indexPath.row < btDelegate.discoveredQueues.count {
            let peripheral = btDelegate.discoveredQueues[indexPath.row]
            let queueInfo = btDelegate.discoveredQueueInfo[peripheral]!
            
            cell.queueNameLabel.text = queueInfo.hostname
            cell.queuePlatformLabel.text = queueInfo.platform.toString()
            cell.queueNumParticipants.text = "\(queueInfo.numParticipants)"
            cell.buttonClicked = {
                self.btDelegate.connectToQueue(peripheral)
                DispatchQueue.main.async {
                    self.joinButtonPressed()
                }
            }
        }
        return cell
        
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btDelegate.discoveredQueues.count
    }
}





