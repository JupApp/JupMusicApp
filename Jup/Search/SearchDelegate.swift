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
import SwiftyJSON


class SearchDelegate {
    
    var amLibrary: AMLibrary = AMLibrary()
    var amCatalogue: AMCatalogue = AMCatalogue()
    
    var amDevToken: String?
    var amUserToken: String?
    
    var spotifyLibrary: SpotifyLibrary = SpotifyLibrary()
    var spotifyCatalogue: SpotifyCatalogue = SpotifyCatalogue()

    var spotifyDevToken: String?
    
    let cloudController = SKCloudServiceController()
    var parentVC: SearchVC?
    
    init() {
        
    }
    
    /*
     Searches Apple Music global catalogue for songs related to search query
     */
    func searchAMCatalogue(_ searchQuery: String) {
        guard let devToken = amDevToken else {
            // Original Token most likely expired, get new one
            do {try setNewAMAccessToken {
                self.searchAMCatalogue(searchQuery)
            }} catch {}
            return
        }
        // reset search results to empty
        amCatalogue.searchResults = []
        //perform search call
        amCatalogue.searchCatalogue(searchQuery, devToken)
    }
    
    /*
     Searches user's personal Apple Music library playlists, and populates into tableview
     */
    func searchAMLibrary() {
        guard let devToken = amDevToken else {
            // Original Token most likely expired, get new one
            do {try setNewAMAccessToken {
                self.searchAMLibrary()
            }} catch {}
            return
        }
        guard let _ = amUserToken else {
            cloudController.requestUserToken(forDeveloperToken: amDevToken!) {data, error in
                if let _ = error {
                    /*
                     Alert User that app was unable to get user token for AM
                     Probably because user has not authorized this app to use library or
                     user does not have apple ID??
                     */
                    return
                }
                if let token = data {
                    self.amUserToken = token
                    self.searchAMLibrary()
                }
                return
            }
            return
        }
        if !amLibrary.playlistNames.isEmpty {
            return
        }
        amLibrary.searchPlaylists(devToken, amUserToken!)
    }
    
    /*
     Searches Spotify global catalogue for songs related to search query
     */
    func searchSpotifyCatalogue(_ searchQuery: String) {
        guard let devToken = spotifyDevToken else {
            // original development access token probably expired, get new one
            setNewSpotifyAccessToken {
                self.searchSpotifyCatalogue(searchQuery)
            }
            return
        }
        // reset search results to empty
        spotifyCatalogue.searchResults = []
        //perform search call
        spotifyCatalogue.searchCatalogue(searchQuery, devToken)
    }
    
    /*
     Searches user's personal Spotify library playlists, and populates into tableview
     */
    func searchSpotifyLibrary() {
        spotifyLibrary.searchPlaylists("", "")
    }
    
    //MUST OVERRIDE
    func requestSong() {
        fatalError()
    }
    
    
    /*
     Creates new Apple Music JWTToken and sets new userToken
     */
    func setNewAMAccessToken(completionHandler: @escaping () -> ()) throws {
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
        amDevToken = try myJWT.sign(using: myJWTSigner)
        if amDevToken != nil {
            completionHandler()
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
    
    /*
     Requests new Authorization token
     */
    func setNewSpotifyAccessToken(completionHandler: @escaping () -> ()) {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body = "grant_type=client_credentials"
        request.httpBody = body.data(using: String.Encoding.utf8)
        
        let clientID: String = "93de9a96fb6c4cb39844ac6e98427885"
        let clientSecret: String = "bc693736cf6d40389102d369243384ff"
        let encodedHeader: String = Data("\(clientID):\(clientSecret)".utf8).base64EncodedString()
        request.setValue("Basic \(encodedHeader)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                
            // Check for Error
            if let error = error {
                print("Error took place \(error)")
                return
            }
     
            // Convert HTTP Response Data to a String
            let jsonData: JSON
            do {try jsonData = JSON(data: data!)} catch{ print("bad data"); return}
            self.spotifyDevToken = jsonData["access_token"].stringValue
            completionHandler()
        }
        task.resume()
    }
    
    
}
