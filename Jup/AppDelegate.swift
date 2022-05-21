//
//  AppDelegate.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate, SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // ########### SPOTIFY AUTHORIZATION CODE BELOW ####################
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.expirationDate = session.expirationDate
        bringBackToVC?(nil)
        bringBackToVC = nil
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        //maybe dont callback
        bringBackToVC?(error)
        bringBackToVC = nil
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.expirationDate = session.expirationDate
        bringBackToVC?(nil)
        bringBackToVC = nil
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let parameters = appRemote.authorizationParameters(from: url);
        self.sessionManager.application(app, open: url, options: options)
        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = access_token
            self.accessToken = access_token
        }
        return true
    }
    
    let SpotifyClientID = "93de9a96fb6c4cb39844ac6e98427885"
    let SpotifyRedirectURL = "jup-spotify-login://spotify-login-callback"
    static let kAccessTokenKey = "access-token-key"
    static let kRefreshTokenKey = "refresh-token-key"
    static let kExpirationDate = "expiration-date"
    
    var openingSpotifyApp = false
    
    var bringBackToVC: ((Error?) -> ())?

    lazy var configuration = SPTConfiguration(
      clientID: SpotifyClientID,
      redirectURL: URL(string: SpotifyRedirectURL)!
    )
    
    lazy var sessionManager: SPTSessionManager = {
      if let tokenSwapURL = URL(string: "https://jup-music-queue.herokuapp.com/api/token"),
         let tokenRefreshURL = URL(string: "https://jup-music-queue.herokuapp.com/api/refresh_token") {
        self.configuration.tokenSwapURL = tokenSwapURL
        self.configuration.tokenRefreshURL = tokenRefreshURL
        self.configuration.playURI = ""
      }
      let manager = SPTSessionManager(configuration: self.configuration, delegate: self)
      return manager
    }()
    
    func connectToSpotify() {
        let requestedScopes: SPTScope = [.appRemoteControl, .userTopRead, .playlistReadPrivate, .playlistReadCollaborative, .userReadPrivate]
        sessionManager.initiateSession(with: requestedScopes, options: .default)
        return

    }
    
    func connectToSpotify(completionHandler: @escaping (Error?) -> ()) {
        bringBackToVC = completionHandler
        connectToSpotify()
    }
    
    // taken from demo app in spotify ios sdk
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: AppDelegate.kAccessTokenKey)
        }
    }
    var refreshToken = UserDefaults.standard.string(forKey: kRefreshTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(refreshToken, forKey: AppDelegate.kRefreshTokenKey)
        }
    }
    var expirationDate = UserDefaults.standard.object(forKey: kExpirationDate) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(expirationDate, forKey: AppDelegate.kExpirationDate)
        }
    }
    
    lazy var appRemote: SPTAppRemote = {
      let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .none)
      appRemote.connectionParameters.accessToken = self.accessToken
      appRemote.delegate = self
      return appRemote
    }()
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        bringBackToVC?(nil)
        bringBackToVC = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        bringBackToVC?(error)
        bringBackToVC = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        /*
         TO-DO deal with this
         */
        bringBackToVC?(error)
        bringBackToVC = nil
    }
    
    func connect(_ uri: String, completionHandler: @escaping (Error?) -> ()) {
        bringBackToVC = completionHandler
        self.appRemote.authorizeAndPlayURI(uri)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
      if self.appRemote.isConnected {
        self.appRemote.disconnect()
      }
    }

    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
    }
    
}

