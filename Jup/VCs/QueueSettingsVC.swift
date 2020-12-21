//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/11/20.
//

import UIKit

class QueueSettingsVC: UITableViewController, UITextFieldDelegate{

    @IBOutlet weak var voteQueueSwitch: UISwitch!
    @IBOutlet weak var strictQueueSwitch: UISwitch!
    @IBOutlet weak var allowRepeatsSwitch: UISwitch!
    @IBOutlet weak var passwordSwitch: UISwitch!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var platformChoiceControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        // Do any additional setup after loading the view.
        strictQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        voteQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    //Zachs Attempt to make text field go away with return key
    func usernameTextFielfShouldReturn(_ usernameTextField: UITextField) -> Bool{
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
        
    @objc func switchChanged(sender: UISwitch!) {
    
        if !sender.isOn {
            return
        }
        if sender != strictQueueSwitch && strictQueueSwitch.isOn {
            strictQueueSwitch.setOn(false, animated: true)
                
        }
        if sender != voteQueueSwitch && voteQueueSwitch.isOn {
                voteQueueSwitch.setOn(false, animated: true)

        }
    }
}


