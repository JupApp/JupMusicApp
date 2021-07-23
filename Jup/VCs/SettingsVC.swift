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

class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    static let usernameKey: String = "username"
    let btDelegate: BTParticipantDelegate = BTParticipantDelegate()

    @IBOutlet weak var voteQueueControl: UISegmentedControl!
    @IBOutlet weak var queueTypeControl: UISegmentedControl!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var queueTableView: UITableView!
    
    @IBOutlet weak var queueModeView: UIView!
    @IBOutlet weak var queueTypeView: UIView!
    @IBOutlet weak var hostButtonView: UIView!
    
    
    var platform: Platform = .APPLE_MUSIC
    var queueType: QueueType {
        queueTypeControl.selectedSegmentIndex == 0 ? .STRICT : .VOTING
    }
    
    @IBOutlet weak var platformChoiceControl: UISegmentedControl!
    
    let musicServicAert = UIAlertController(title: "Access to selected Music Service not available", message: nil, preferredStyle: .alert)
    let authorizeAlert = UIAlertController(title: "Failed to authorize", message: nil, preferredStyle: .alert)
    let usernameAlert = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
    
    var backgroundImageView: UIImageView! = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark

        usernameTextField.delegate = self
        var placeHolderText: String = "username"
        
        if let lastUsedUsername = UserDefaults.standard.string(forKey: SettingsVC.usernameKey) {
            if lastUsedUsername != "" {
                placeHolderText = lastUsedUsername
            }
        }
        usernameTextField.attributedPlaceholder = NSAttributedString(string: placeHolderText,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
                
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //Code to make segmented text field text color black
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        
        platformChoiceControl.addTarget(self, action: #selector(platformControlSwitched(sender:)), for: .valueChanged)
        
        musicServicAert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        usernameAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        authorizeAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        
        btDelegate.settingsVC = self
        queueTableView.register(UINib(nibName: "JoinableQueueCell", bundle: nil), forCellReuseIdentifier: "JoinHostCell")
        
        queueTableView.delegate = self
        queueTableView.allowsSelection = false
        queueTableView.isScrollEnabled = true
        queueTableView.dataSource = self
        
        queueModeView.layer.cornerRadius = 10
        queueTypeView.layer.cornerRadius = 10
        hostButtonView.layer.cornerRadius = 10
        usernameTextField.layer.cornerRadius = 10
        queueTableView.layer.cornerRadius = 10
        
    }
    
    @IBAction func verifyAndSegueToQueue(_ sender: Any) {
        if !checkUsername() {
            return
        }
        
        if platform == .APPLE_MUSIC {
            let authStatus = SKCloudServiceController.authorizationStatus()
            if authStatus == .notDetermined || authStatus == .denied {
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
            } else if authStatus == .authorized {
                SKCloudServiceController().requestCapabilities { capabilities, error in
                    guard capabilities.contains(.musicCatalogPlayback) else {
                        // Does not have apple music
                        self.present(self.musicServicAert, animated: true)
                        return
                    }
                    // user has apple music
                    self.performSegue(withIdentifier: "segueToQueueAsHost", sender: nil)
                    return
                }
            } else {
                //no access, raise alert
                self.present(authorizeAlert, animated: true)
            }
        } else if platform == .SPOTIFY {
                
            // check if user has premium in order to proceed
            SpotifyUtilities.doesHavePremium { (hasPremium) in
                if !hasPremium {
                    /*
                     Alert User doesn't have Spotify Premium
                     */
                    DispatchQueue.main.async {
                        self.present(self.musicServicAert, animated: true)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "segueToQueueAsHost", sender: nil)
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navController = segue.destination as! UINavigationController
        let queueVC = navController.viewControllers[0] as! QueueVC

        if segue.identifier == "segueToQueueAsHost"  {
            queueVC.isHost = true
            queueVC.platform = platform
            
            let username: String = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
            queueVC.host = username
            btDelegate.breakConnections()
            
        } else if segue.identifier == "segueToQueueAsParticipant" {
            queueVC.isHost = false
            queueVC.platform = btDelegate.discoveredQueueInfo[btDelegate.hostPeripheral!]!.platform
            
            btDelegate.queueVC = queueVC
            queueVC.btDelegate = btDelegate
        }
    }
    
    func joinQueueButtonPressed() {
        if !checkUsername() {
            return
        }
            
        self.performSegue(withIdentifier: "segueToQueueAsParticipant", sender: nil)
        return
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinHostCell") as! JoinableQueueCell

        if indexPath.row < btDelegate.discoveredQueues.count {
            let peripheral = btDelegate.discoveredQueues[indexPath.row]
            let queueInfo = btDelegate.discoveredQueueInfo[peripheral]!
            
            cell.queueNameLabel.text = queueInfo.hostname
            cell.queuePlatformLabel.text = queueInfo.platform.toString()
            cell.queueNumParticipants.text = "\(queueInfo.numParticipants)"
            cell.buttonClicked = {
                self.btDelegate.connectToQueue(peripheral)
                DispatchQueue.main.async {
                    self.joinQueueButtonPressed()
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return btDelegate.discoveredQueues.count
    }
    
    private func checkUsername() -> Bool {
        let username: String
        if self.usernameTextField.text == nil || self.usernameTextField.text == "" {
            guard let stored_val = UserDefaults.standard.string(forKey: SettingsVC.usernameKey) else {
                self.present(self.usernameAlert, animated: true)
                return false
            }
            guard stored_val != "" else {
                self.present(self.usernameAlert, animated: true)
                return false
            }
            username = stored_val
        } else {
            username = self.usernameTextField.text!
            UserDefaults.standard.set(username, forKey: SettingsVC.usernameKey)
        }
        return true
    }
    
    
    @objc func platformControlSwitched(sender: UISegmentedControl) {
        platform.toggle()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}


