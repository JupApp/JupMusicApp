//
//  ParticipantSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit

class ParticipantSettingsVC: UIViewController {
    
    @IBOutlet weak var joinQueueButton: UIButton!
    @IBOutlet weak var joinableQueuesTable: UITableView!
    @IBOutlet weak var displayNameTextField: UITextField!
    
    
    
        
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        joinQueueButton.layer.cornerRadius = 8
        displayNameTextField.layer.cornerRadius = 5
        displayNameTextField.attributedPlaceholder = NSAttributedString(string: "username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        
    
        }
    
}





