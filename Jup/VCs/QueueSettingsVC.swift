//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/11/20.
//
import UIKit
import StoreKit


class QueueSettingsVC: UITableViewController, UITextFieldDelegate{
    
    static let usernameKey: String = "username"

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
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Code to make segmented text field text color black
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        
        platformChoiceControl.addTarget(self, action: #selector(choiceControlSwitched(sender:)), for: .valueChanged)
        
        musicServicAert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
<<<<<<< HEAD
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "username", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])


=======
        usernameAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
>>>>>>> b9512287fef6dc9e173c182cf59bf264f4f8d70d

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
                    case .authorized:
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
                    default: break
                    }
                }
            } else if (SKCloudServiceController.authorizationStatus() == .authorized) {
                if usernameTextField.text == nil || usernameTextField.text == "" {
                    guard let stored_val = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey) else {

                        self.present(usernameAlert, animated: true)
                        return
                    }
                    guard stored_val != "" else {

                        self.present(self.usernameAlert, animated: true)
                        return
                    }

                    performSegue(withIdentifier: "segueToQueue", sender: nil)
                    return
                }
                let currentUserName = usernameTextField.text!
                UserDefaults.standard.set(currentUserName, forKey: QueueSettingsVC.usernameKey)
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


