//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Nick Venanzi on 7/21/21.
//

import Foundation

class QueueSettingsVC: UIViewController {
    
    var queueVC: QueueVC?
    @IBOutlet weak var queueTypeControl: UISegmentedControl!
    @IBOutlet weak var hostQueueEditControl: UISwitch!
    @IBOutlet weak var selfLikingControl: UISwitch!
    @IBOutlet weak var queueOpenControl: UISwitch!
    
    @IBOutlet weak var view1: UIVisualEffectView!
    @IBOutlet weak var view2: UIVisualEffectView!
    @IBOutlet weak var view3: UIVisualEffectView!
    @IBOutlet weak var view4: UIVisualEffectView!
    @IBOutlet weak var view5: UIVisualEffectView!
    @IBOutlet weak var view7: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !queueVC!.isHost {
            queueTypeControl.isUserInteractionEnabled = false
            hostQueueEditControl.isUserInteractionEnabled = false
            selfLikingControl.isUserInteractionEnabled = false
            queueOpenControl.isUserInteractionEnabled = false
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        if !(queueVC?.isHost ?? false) {
        updateSettings(animated)
//        }
    }
        
    @IBAction func toggleOpenCloseQueue(_ sender: Any) {
        if queueOpenControl.isOn {
            queueVC?.btDelegate.openQueue()
        } else {
            queueVC?.btDelegate.closeQueue()
        }
        queueVC?.settings.queueOpen = queueOpenControl.isOn
        queueVC?.btDelegate.updateQueueSnapshot()
    }
    
    @IBAction func toggleHostEditing(_ sender: Any) {
        if hostQueueEditControl.isOn {
            // host control
            queueTypeControl.selectedSegmentIndex = 0
            queueVC?.settings.hostControlOn = true
            
            queueVC!.tableView.setEditing(true, animated: true)
        } else {
            queueVC!.tableView.setEditing(false, animated: true)
        }
        queueVC?.settings.hostEditingOn = hostQueueEditControl.isOn
        queueVC?.btDelegate.updateQueueSnapshot()
        queueVC?.tableView.reloadData()
    }
    
    @IBAction func toggleHostControlOrVoting(_ sender: Any) {
        if queueTypeControl.selectedSegmentIndex == 1 {
            hostQueueEditControl.setOn(false, animated: true)
            queueVC?.settings.hostEditingOn = false
        } else {
            selfLikingControl.setOn(false, animated: true)
            queueVC?.settings.selfLikingOn = false
        }
        queueVC?.settings.hostControlOn = queueTypeControl.selectedSegmentIndex == 0
        queueVC?.btDelegate.updateQueueSnapshot()
        queueVC?.tableView.reloadData()
    }
    
    @IBAction func toggleSelfLiking(_ sender: Any) {
        if queueTypeControl.selectedSegmentIndex == 0 && selfLikingControl.isOn {
            // no self liking while in host control mode
            selfLikingControl.setOn(false, animated: true)
            queueVC?.settings.selfLikingOn = false
        } else {
            queueVC?.settings.selfLikingOn = true
        }
        queueVC?.btDelegate.updateQueueSnapshot()
        queueVC?.tableView.reloadData()
    }
    
    @IBAction func clearQueue(_ sender: Any) {
        if queueVC!.isHost {
            queueVC?.mpDelegate.clearQueue()
        }
    }
    
    @IBAction func exitQueue(_ sender: Any) {
        let exitAlert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        exitAlert.addAction(UIAlertAction(title: "Leave the Queue", style: .destructive, handler: {
            (action) in
            self.dismiss(animated: false, completion: {
                self.queueVC!.returnToSettingsSegue(action)
            })
        }))
        exitAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(exitAlert, animated: true)
    }
    
    func updateSettings(_ animated: Bool) {
        let settings: Settings = queueVC!.settings
        queueTypeControl.selectedSegmentIndex = settings.hostControlOn ? 0 : 1
        queueOpenControl.setOn(settings.queueOpen, animated: animated)
        hostQueueEditControl.setOn(settings.hostEditingOn, animated: animated)
        selfLikingControl.setOn(settings.selfLikingOn, animated: animated)
    }
}
