//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/11/20.
//
import UIKit
import StoreKit


class QueueSettingsVC: UITableViewController, UITextFieldDelegate{

    @IBOutlet weak var voteQueueSwitch: UISwitch!
    @IBOutlet weak var strictQueueSwitch: UISwitch!
    @IBOutlet weak var allowRepeatsSwitch: UISwitch!
    @IBOutlet weak var passwordSwitch: UISwitch!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    var platform: Platform = .APPLE_MUSIC
    var openedSpotify: Bool = false
    
    @IBOutlet weak var platformChoiceControl: UISegmentedControl!
    
    let musicServicAert = UIAlertController(title: "Access to selected Music Service not available", message: nil, preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        // Do any additional setup after loading the view.
        strictQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        voteQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Code to make segmented text field text color black
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        
        platformChoiceControl.addTarget(self, action: #selector(choiceControlSwitched(sender:)), for: .valueChanged)
        
        musicServicAert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])



    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if openedSpotify {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.bringBackToVC?()
            openedSpotify = false 
        }
    }
    
    @IBSegueAction func segueToQueue(_ coder: NSCoder) -> QueueVC? {
        let queueVC = QueueVC(coder: coder)
        queueVC?.isHost = true
        queueVC?.platform = platform
        return queueVC
    }
    
    
    @IBAction func verifyAndSegueToQueue(_ sender: Any) {
        if platform == .APPLE_MUSIC {
            if SKCloudServiceController.authorizationStatus() == .notDetermined {
                SKCloudServiceController.requestAuthorization {(status:
                    SKCloudServiceAuthorizationStatus) in
                    switch status {
                    case .authorized:                 self.performSegue(withIdentifier: "segueToQueue", sender: nil)
                        return
                    default: break
                    }
                }
            } else if (SKCloudServiceController.authorizationStatus() == .authorized) {
                performSegue(withIdentifier: "segueToQueue", sender: nil)
                return
            }

            //no access, raise alert
            self.present(musicServicAert, animated: true)
        } else if platform == .SPOTIFY {
            openedSpotify = true
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            appDelegate.connectToSpotify {
                print("Callback initiated")
                guard let expired = appDelegate.sessionManager.session?.isExpired else {
                    print("No session")
                    self.present(self.musicServicAert, animated: true)
                    return
                }
                if expired {
                    print("Session expired")
                    self.present(self.musicServicAert, animated: true)
                    return
                }
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "segueToQueue", sender: nil)
                }
                
            }
        }
        
    }
 
    
    @objc func choiceControlSwitched(sender: UISegmentedControl) {
        platform.toggle()
        platform.printPlatform()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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


