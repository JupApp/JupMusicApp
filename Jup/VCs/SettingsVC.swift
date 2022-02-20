//
//  QueueSettingsVC.swift
//  Jup
//
//  Created by Zach Venanzi on 12/11/20.
//
import UIKit
import StoreKit


class SettingsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    static let usernameKey: String = "username"
    let btDelegate: BTParticipantDelegate = BTParticipantDelegate()

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var queueTableView: UITableView!
    
    @IBOutlet weak var hostButtonView: UIView!
    @IBOutlet weak var usernameView: UIView!
    @IBOutlet weak var amSelected: UIButton!
    @IBOutlet weak var spotifySelected: UIButton!
    
    @IBOutlet weak var amIcon: UIButton!
    @IBOutlet weak var spotifyIcon: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    
    
    var activityIndicator = UIActivityIndicatorView(style: .large)
    var platform: Platform = .APPLE_MUSIC
    
    let musicServicAert = UIAlertController(title: "Access to selected Music Service not available", message: nil, preferredStyle: .alert)
    let authorizeAlert = UIAlertController(title: "Failed to authorize", message: nil, preferredStyle: .alert)
    let usernameAlert = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
    
    var backgroundImageView: UIImageView! = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .dark

        view.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        
        usernameTextField.delegate = self
        var placeHolderText: String = "username"
        
        if let lastUsedUsername = UserDefaults.standard.string(forKey: SettingsVC.usernameKey) {
            if lastUsedUsername != "" {
                placeHolderText = lastUsedUsername
            }
        }
        usernameTextField.attributedPlaceholder = NSAttributedString(string: placeHolderText,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
                
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        musicServicAert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        usernameAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        authorizeAlert.addAction(UIAlertAction(title: "Return", style: .cancel, handler: nil))
        
        btDelegate.settingsVC = self
        queueTableView.register(UINib(nibName: "JoinableQueueCell", bundle: nil), forCellReuseIdentifier: "JoinHostCell")
        
        queueTableView.delegate = self
        queueTableView.isScrollEnabled = true
        queueTableView.dataSource = self
        queueTableView.tableFooterView = UIView.init(frame: CGRect.zero)
        queueTableView.becomeFirstResponder()
        
        hostButtonView.layer.cornerRadius = 10
        usernameTextField.layer.cornerRadius = 10
        queueTableView.layer.cornerRadius = 10
        usernameView.layer.cornerRadius = 10
        joinButton.layer.cornerRadius = 5

    }
    
    @IBAction func selectAM(_ sender: Any) {
        amSelected.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        spotifySelected.setImage(UIImage(systemName: "circle"), for: .normal)
        platform = .APPLE_MUSIC
    }
    
    @IBAction func selectSpotify(_ sender: Any) {
        amSelected.setImage(UIImage(systemName: "circle"), for: .normal)
        spotifySelected.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        platform = .SPOTIFY
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
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            activityIndicator.startAnimating()
            // check if user has premium in order to proceed
            SpotifyUtilities.doesHavePremium(appDelegate.accessToken) { (hasPremium) in
                print("Has Premium: \(hasPremium)")
                if !hasPremium {
                    /*
                     Alert User doesn't have Spotify Premium
                     */
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.present(self.musicServicAert, animated: true)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.performSegue(withIdentifier: "segueToQueueAsHost", sender: nil)
                }
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let navController = segue.destination as! UINavigationController
        let queueVC = navController.viewControllers[0] as! QueueVC
        let uniqueID: String = UIDevice.current.identifierForVendor!.uuidString
        if segue.identifier == "segueToQueueAsHost"  {
            queueVC.isHost = true
            queueVC.platform = platform
            let username: String = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
            queueVC.participants.append(uniqueID)
            queueVC.participantIDsToUsernames[uniqueID] = username

            btDelegate.breakConnections()
            
        } else if segue.identifier == "segueToQueueAsParticipant" {
            queueVC.isHost = false
            queueVC.platform = btDelegate.discoveredQueueInfo[btDelegate.hostPeripheral!]!.platform 
            
            btDelegate.queueVC = queueVC
            queueVC.btDelegate = btDelegate
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard btDelegate.discoveredQueues.count > 0 else {
            return nil
        }
        return indexPath
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.checkUsername() {
            let peripheral = btDelegate.discoveredQueues[indexPath.row]
            self.btDelegate.connectToQueue(peripheral)
            self.performSegue(withIdentifier: "segueToQueueAsParticipant", sender: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JoinHostCell") as! JoinableQueueCell
        if indexPath.row < btDelegate.discoveredQueues.count {
            let peripheral = btDelegate.discoveredQueues[indexPath.row]
            let queueInfo = btDelegate.discoveredQueueInfo[peripheral]!
            print(queueInfo)
            cell.queueNameLabel.text = queueInfo.hostname
            cell.queuePlatformLabel.text = queueInfo.platform.toString()
            cell.queueNumParticipants.text = "\(queueInfo.numParticipants)"
        } else if indexPath.row == 0 {
            cell.queueNameLabel.text = "No Queues Available"
            cell.queuePlatformLabel.text = "Host must open app to make queue available to join"
            cell.queueNumParticipants.text = ""
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var number: Int = btDelegate.discoveredQueues.count
        if btDelegate.discoveredQueues.count > 0{
            number = btDelegate.discoveredQueues.count
        }
        else{
            number = 1
        }
        return number
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

    @objc func dismissKeyboard() {
        view.endEditing(false)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}


