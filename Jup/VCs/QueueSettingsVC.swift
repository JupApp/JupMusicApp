//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Nick Venanzi on 7/21/21.
//

import Foundation

class QueueSettingsVC: UIViewController {
    
    var queueVC: QueueVC?
    @IBOutlet weak var hostQueueEditControl: UISwitch!
    @IBOutlet weak var selfLikingControl: UISwitch!
    @IBOutlet weak var queueOpenControl: UISwitch!
    
    @IBOutlet weak var view2: UIVisualEffectView!
    @IBOutlet weak var view3: UIVisualEffectView!
    @IBOutlet weak var view4: UIVisualEffectView!
    @IBOutlet weak var view5: UIVisualEffectView!
    @IBOutlet weak var view7: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !queueVC!.isHost {
            hostQueueEditControl.isUserInteractionEnabled = false
            selfLikingControl.isUserInteractionEnabled = false
            queueOpenControl.isUserInteractionEnabled = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateSettings(animated)
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
        queueVC?.settings.hostEditingOn = hostQueueEditControl.isOn
        queueVC?.btDelegate.updateQueueSnapshot()
        queueVC?.tableView.reloadData()
    }
    
    @IBAction func toggleSelfLiking(_ sender: Any) {
        queueVC?.settings.selfLikingOn = selfLikingControl.isOn
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
        queueOpenControl.setOn(settings.queueOpen, animated: animated)
        hostQueueEditControl.setOn(settings.hostEditingOn, animated: animated)
        selfLikingControl.setOn(settings.selfLikingOn, animated: animated)
    }
}
