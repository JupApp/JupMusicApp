//
//  ParticipantSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit

class ParticipantSettingsVC: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var displayNameTextField: UITextField!
        
    let usernameAlert = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
        
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //joinQueueButton.layer.cornerRadius = 8
        displayNameTextField.layer.cornerRadius = 5
        var placeHolderText: String = "username"
        if let lastUsedUsername = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) {
            if lastUsedUsername != "" {
                placeHolderText = lastUsedUsername
            }
        }
        displayNameTextField.delegate = self
        displayNameTextField.attributedPlaceholder = NSAttributedString(string: placeHolderText,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        //joinQueueButton.addTarget(self, action: #selector(joinButtonPressed), for: .touchUpInside)
    
        usernameAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
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
    
    @IBSegueAction func segueToQueue(_ coder: NSCoder) -> QueueVC? {
        let queueVC = QueueVC(coder: coder)
        queueVC?.isHost = false
        // TO-DO gather data from selected queue
        queueVC?.platform = .APPLE_MUSIC
        return queueVC
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
    
}





