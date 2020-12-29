//
//  AppDelegate.swift
//  Jup
//
//  Created by Zach Venanzi on 11/27/20.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate, SPTSessionManagerDelegate, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // ########### SPOTIFY AUTHORIZATION CODE BELOW ####################
    
    func sessionManager(manager: SPTSessionManager, didInitiate session: SPTSession) {
        print("success", session)
        bringBackToVC?()
        bringBackToVC = nil
    }
    
    func sessionManager(manager: SPTSessionManager, didFailWith error: Error) {
        print("error", error)
        bringBackToVC?()
        bringBackToVC = nil
    }
    
    func sessionManager(manager: SPTSessionManager, didRenew session: SPTSession) {
        print("renewed", session)
        bringBackToVC?()
        bringBackToVC = nil
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      self.sessionManager.application(app, open: url, options: options)
      return true
    }
    
    let SpotifyClientID = "93de9a96fb6c4cb39844ac6e98427885"
    let SpotifyRedirectURL = URL(string: "jup-spotify-login://spotify-login-callback")!
    
    var bringBackToVC: (() -> ())?

    lazy var configuration = SPTConfiguration(
      clientID: SpotifyClientID,
      redirectURL: SpotifyRedirectURL
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
        let requestedScopes: SPTScope = [.appRemoteControl, .userReadRecentlyPlayed, .userTopRead, .playlistReadPrivate, .playlistReadCollaborative, .userLibraryRead]
        guard let session = sessionManager.session else {
            sessionManager.initiateSession(with: requestedScopes, options: .default)
            return
        }
        if session.isExpired == true {
            sessionManager.renewSession()
            return
        }
        bringBackToVC?()
        bringBackToVC = nil
        
    }
    
    func connectToSpotify(completionHandler: @escaping () -> ()) {
        bringBackToVC = completionHandler
        connectToSpotify()
    }
    
    lazy var appRemote: SPTAppRemote = {
      let appRemote = SPTAppRemote(configuration: self.configuration, logLevel: .debug)
        appRemote.connectionParameters.accessToken = sessionManager.session?.accessToken
      appRemote.delegate = self
      return appRemote
    }()
    
    var tryReconnecting = true
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        print("\n\n\n\n\n\nconnected to spotify app\n\n\n\n\n\n\n\n")
        bringBackToVC?()
        bringBackToVC = nil
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("\n\n\n\n\n\nfailed to connect to spotify app\n\n\n\n\n\n")
        print(error.debugDescription)
        print("But is it connected...? - \(appRemote.isConnected)")
        
        if tryReconnecting {
            connect("", completionHandler: bringBackToVC!)
            tryReconnecting = false
        } else {
            bringBackToVC?()
            bringBackToVC = nil
            tryReconnecting = true
        }
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("\n\n\n\n\n\ndisconnected from spotify app\n\n\n\n\n\n")
        connect("") {
            print("attempted to connect back to spotify app after disconnecting")
        }
        if tryReconnecting {
            if bringBackToVC == nil {
                bringBackToVC = {
                    print("attempted to connect back to spotify app after disconnecting")
                }
            }
            connect("", completionHandler: bringBackToVC!)
            bringBackToVC = nil
            tryReconnecting = false
        } else {
            bringBackToVC?()
            bringBackToVC = nil
            tryReconnecting = true
        }

    }
    
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        print("Player state changed")
    }
    
    func connect(_ uri: String, completionHandler: @escaping () -> ()) {
        connect(uri, 0, completionHandler: completionHandler)
    }
    
    func connect(_ uri: String, _ playbackPosition: Int, completionHandler: @escaping () -> ()) {
        bringBackToVC = completionHandler
        if self.appRemote.isConnected {
            
            self.appRemote.playerAPI?.play(uri, callback: { (_, e) in
                if let _ = e {
                    print("Was connected, but failed to play song...")
                } else {
                    self.appRemote.playerAPI?.seek(toPosition: playbackPosition, callback: { (_, _) in
                        self.bringBackToVC?()
                        self.bringBackToVC = nil
                    })
                }
            })
        } else {
            SPTAppRemote.checkIfSpotifyAppIsActive { (active) in
                if active {
                    self.bringBackToVC = {
                        print("hopefully connected by now... \(self.appRemote.isConnected)")
                        self.appRemote.playerAPI?.play(uri, callback: { (_, e) in
                            if let _ = e {
                                print("Was connected, but failed to play song...")
                            } else {
                                self.appRemote.playerAPI?.seek(toPosition: playbackPosition, callback: { (_, _) in })
                            }
                        })
                    }
                    self.appRemote.connect()
                } else {
                    self.appRemote.authorizeAndPlayURI(uri)
                }
            }
        }
    }

    
}

