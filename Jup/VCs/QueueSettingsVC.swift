//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/11/20.
//

import UIKit

class QueueSettingsVC: UITableViewController{

    @IBOutlet weak var voteQueueSwitch: UISwitch!
    @IBOutlet weak var strictQueueSwitch: UISwitch!
    @IBOutlet weak var allowRepeatsSwitch: UISwitch!
    
    @IBOutlet weak var passwordSwitch: UISwitch!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        strictQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        voteQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
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


