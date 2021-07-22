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
    @IBOutlet weak var queueOpenControl: UISwitch!
    @IBOutlet weak var hostQueueEditControl: UISwitch!
    @IBOutlet weak var selfLikingControl: UISwitch!
    
    @IBOutlet weak var view1: UIVisualEffectView!
    @IBOutlet weak var view2: UIVisualEffectView!
    @IBOutlet weak var view3: UIVisualEffectView!
    @IBOutlet weak var view4: UIVisualEffectView!
    @IBOutlet weak var view5: UIVisualEffectView!
    @IBOutlet weak var view6: UIVisualEffectView!
    @IBOutlet weak var view7: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func spotifySignOut(_ sender: Any) {
        /*
         TO-DO
         */
    }
    
    @IBAction func clearQueue(_ sender: Any) {
        /*
         TO-DO
         */
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
}
