//
//  File.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit

class HostVC: UIViewController
{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        strictQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        roundQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        voteQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        songLimitSlider.addTarget(self, action: #selector(songLimitSlider(sender:)), for: .valueChanged);
    }
    
    @IBOutlet weak var strictQueueSwitch: UISwitch!
    @IBOutlet weak var roundQueueSwitch: UISwitch!
    @IBOutlet weak var voteQueueSwitch: UISwitch!
    @IBOutlet weak var songLimitSlider: UISlider!
    @IBOutlet weak var songLimitValue: UILabel!
    @IBOutlet weak var switchDescription: UILabel!
    
    
    
   //This code is for the song slider
    @objc func songLimitSlider(sender: Any) {
        songLimitValue.text = String(format: "%i",Int(songLimitSlider.value))
       
       
    
            
    }
    @objc func switchChanged(sender: UISwitch) {
        // insert appropriate label
        if sender == strictQueueSwitch {
            switchDescription.text = "Songs will be played in the order that they were added to the queue."
        } else if sender == roundQueueSwitch {
            switchDescription.text = "Songs will be ordered in the queue by a rotation of the participants."
            //"Songs will be ordered in the queue by a rotation of the participants."
        } else if sender == voteQueueSwitch {
            switchDescription.text = "Songs in the queue will be ordered by total number of votes."
        }
        
        // do nothing if switching off
        if !sender.isOn {
            switchDescription.text = "Select a Queue Style"
            return
        }
        if sender != strictQueueSwitch && strictQueueSwitch.isOn {
            strictQueueSwitch.setOn(false, animated: true)
                
        }
        if sender != voteQueueSwitch && voteQueueSwitch.isOn {
                voteQueueSwitch.setOn(false, animated: true)

        }
        if sender != roundQueueSwitch && roundQueueSwitch.isOn {
            roundQueueSwitch.setOn(false, animated: true)
                    
        }
        
        }
        
}






