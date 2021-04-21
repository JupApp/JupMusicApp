//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/11/20.
//
import UIKit
import StoreKit

enum QueueType {
    case VOTING
    case STRICT
}

class QueueSettingsVC: UITableViewController, UITextFieldDelegate{
    
    static let usernameKey: String = "username"

    @IBOutlet weak var voteQueueSwitch: UISwitch!
    @IBOutlet weak var strictQueueSwitch: UISwitch!
    @IBOutlet weak var passwordSwitch: UISwitch!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    var platform: Platform = .APPLE_MUSIC
    var queueType: QueueType {
        voteQueueSwitch.isOn ? .VOTING : .STRICT
    }
    
    @IBOutlet weak var platformChoiceControl: UISegmentedControl!
    
    let musicServicAert = UIAlertController(title: "Access to selected Music Service not available", message: nil, preferredStyle: .alert)
    let authorizeAlert = UIAlertController(title: "Failed to authorize", message: nil, preferredStyle: .alert)
    let usernameAlert = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.delegate = self
        var placeHolderText: String = "username"
        
        if let lastUsedUsername = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) {
            if lastUsedUsername != "" {
                placeHolderText = lastUsedUsername
            }
        }
        usernameTextField.attributedPlaceholder = NSAttributedString(string: placeHolderText,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        
        // Do any additional setup after loading the view.
        strictQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        voteQueueSwitch.addTarget(self, action: #selector(switchChanged(sender:)), for: .valueChanged);
        voteQueueSwitch.setOn(true, animated: false)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Code to make segmented text field text color black
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        
        platformChoiceControl.addTarget(self, action: #selector(choiceControlSwitched(sender:)), for: .valueChanged)
        
        musicServicAert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        usernameAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        authorizeAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
    }
    
    
    @IBAction func verifyAndSegueToQueue(_ sender: Any) {
        if platform == .APPLE_MUSIC {
            if SKCloudServiceController.authorizationStatus() == .notDetermined {
                SKCloudServiceController.requestAuthorization {(status:
                    SKCloudServiceAuthorizationStatus) in
                    switch status {
                    case .authorized:
                        self.verifyAndSegueToQueue(sender)
                        break
                    default:
                        /*
                         User failed to authorize, show alert
                         */
                        self.present(self.authorizeAlert, animated: true)
                        return
                    }
                }
            } else if (SKCloudServiceController.authorizationStatus() == .authorized) {
                SKCloudServiceController().requestCapabilities { capabilities, error in
                    guard capabilities.contains(.musicCatalogPlayback) else {
                        // Does not have apple music
                        self.present(self.musicServicAert, animated: true)
                        return
                    }
                    // user has apple music
                    if self.usernameTextField.text == nil || self.usernameTextField.text == "" {
                        guard let stored_val = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) else {
                            self.present(self.usernameAlert, animated: true)
                            return
                        }
                        guard stored_val != "" else {
                            self.present(self.usernameAlert, animated: true)
                            return
                        }
                        self.performSegue(withIdentifier: "segueToQueue", sender: nil)
                        return
                    }
                    let currentUserName = self.usernameTextField.text!
                    UserDefaults.standard.set(currentUserName, forKey: QueueSettingsVC.usernameKey)
                    self.performSegue(withIdentifier: "segueToQueue", sender: nil)
                    return
                }
            } else {
                //no access, raise alert
                self.present(authorizeAlert, animated: true)
            }
        } else if platform == .SPOTIFY {
                
            // check if user has premium in order to proceed
            SpotifyUtilities.doesHavePremium { (hasPremium) in
                guard hasPremium else {
                    /*
                     Alert User doesn't have Spotify Premium
                     */
                    DispatchQueue.main.async {
                        self.present(self.musicServicAert, animated: true)
                    }
                    return
                }
                DispatchQueue.main.async {
                    if self.usernameTextField.text == nil || self.usernameTextField.text == "" {
                        guard let stored_val = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) else {
                            self.present(self.usernameAlert, animated: true)
                            return
                        }
                        guard stored_val != "" else {
                            self.present(self.usernameAlert, animated: true)
                            return
                        }
                        self.performSegue(withIdentifier: "segueToQueue", sender: nil)
                        return
                    }
                    let currentUserName = self.usernameTextField.text!
                    UserDefaults.standard.set(currentUserName, forKey: QueueSettingsVC.usernameKey)
                    self.performSegue(withIdentifier: "segueToQueue", sender: nil)
                }
            }
        }
        
    }
 
    
    @objc func choiceControlSwitched(sender: UISegmentedControl) {
        platform.toggle()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
        
    @objc func switchChanged(sender: UISwitch!) {
        if strictQueueSwitch.isOn && voteQueueSwitch.isOn {
            if sender == strictQueueSwitch {
                voteQueueSwitch.setOn(false, animated: true)
            } else {
                strictQueueSwitch.setOn(false, animated: true)
            }
        } else if !strictQueueSwitch.isOn && !voteQueueSwitch.isOn {
            if sender == strictQueueSwitch {
                voteQueueSwitch.setOn(true, animated: true)
            } else {
                strictQueueSwitch.setOn(true, animated: true)
            }
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "segueToQueue" else {
            return
        }
        
        let navController = segue.destination as! UINavigationController
        let queueVC = navController.viewControllers[0] as! QueueVC
        queueVC.isHost = true
        queueVC.platform = platform
    }
    
}


