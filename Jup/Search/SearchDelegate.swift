//
//  SearchDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

import Foundation
import Security
import StoreKit
import SwiftJWT


class SearchDelegate {
    
    var amLibrary: AMLibrary = AMLibrary()
    
    var signedJWTToken: String?
    var userToken: String? {
        didSet {
            parentVC?.loadAppleMusicPersonalPlaylists()
        }
    }
    
    let cloudController = SKCloudServiceController()
    var parentVC: SearchVC?
    
    init() {
        
    }
    
    /*
     Searches Spotify global catalogue for songs related to search query
     */
    func searchSpotifyCatalogue(_ searchQuery: String) {
        
    }
    
    /*
     Searches Apple Music global catalogue for songs related to search query
     */
    func searchAMCatalogue(_ searchQuery: String) {
        
    }
    
    /*
     Searches user's personal Apple Music library playlists, and populates into tableview
     */
    func searchAMLibrary() {
        guard let devToken = signedJWTToken else {
            //
            // alert bad token?
            //
            return
        }
        guard let _ = userToken else {
            //
            // alert cant get user token? possibly dont have apple music
            //
            return
        }
        if !amLibrary.playlistNames.isEmpty {
            return
        }
        amLibrary.searchPlaylists(devToken, userToken!)
        return
    }
    
    /*
     Searches user's personal Spotify library playlists, and populates into tableview
     */
    func searchSpotifyLibrary() {
        
    }
    
    //MUST OVERRIDE
    func requestSong() {
        fatalError()
    }
    
    
    /*
     Creates new JWTToken and sets new userToken
     */
    func setNewSignedJWTToken() throws {
        guard let privateKey = getAMAuthorizationKey() else {
            return
        }
        let keyData = privateKey.data(using: .utf8)!
        let kid = "5CWA2J2HGK"
        let myHeader = Header(kid: kid)
        
        let iss = "LT3MWZH387"
        let now = Date(timeIntervalSinceNow: 0)
        let exp = Date(timeIntervalSinceNow: 1100)
        
        let myClaims = ClaimsStandardJWT(iss: iss, exp: exp, iat: now)
        var myJWT = JWT(header: myHeader, claims: myClaims)
        let myJWTSigner = JWTSigner.es256(privateKey: keyData)
        signedJWTToken = try myJWT.sign(using: myJWTSigner)
        if signedJWTToken != nil {
            cloudController.requestUserToken(forDeveloperToken: signedJWTToken!) {token, _ in
                self.userToken = token }
        }
        
    }
    
    /*
     Retrieves private authorization key to get developer token
     */
    func getAMAuthorizationKey() -> String? {
        do {
            guard let path = Bundle.main.path(forResource: "AuthKey_5CWA2J2HGK", ofType: ".p8") else {
                return nil
            }
            let fileURL = URL(fileURLWithPath: path);
            let data = try Data(contentsOf: fileURL)
            guard let key = String(data: data, encoding: .utf8) else {
                print("Failed to convert data to string")
                return nil
            }
            return key
        }
        catch {
            return nil
        }
    }
    
    
}
