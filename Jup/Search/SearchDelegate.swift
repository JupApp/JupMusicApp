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
    
    var amDevToken: String?
    var amUserToken: String?
    
    var spotifyLibrary: SpotifyLibrary = SpotifyLibrary()
    var spotifyDevToken: String?
    
    let cloudController = SKCloudServiceController()
    var parentVC: SearchVC?
    
    init() {
        
    }
        
    /*
     Searches Apple Music global catalogue for songs related to search query
     */
    func searchAMCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([AppleMusicSongItem]) -> ()) {
        //perform search call
        AppleMusicUtilities.searchCatalogue(searchQuery, completionHandler)
    }
    
    /*
     Searches user's personal Apple Music library playlists, and populates into tableview
     */
    func searchAMLibrary() {
        guard let devToken = amDevToken else {
            // Original Token most likely expired, get new one
            do {try AppleMusicUtilities.setNewAMAccessToken { token in
                guard token != nil else {
                    return
                }
                self.amDevToken = token
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
        amLibrary.searchPlaylists(devToken, amUserToken!) {
            // populates results into tableview
            var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
            snap.appendSections(["Playlists"])
            snap.appendItems(self.amLibrary.playlistIDs.map({ (id) -> PlaylistItem in
                PlaylistItem(self.amLibrary.playlistNames[id]!, id)
            }))
            self.parentVC?.datasource.apply(snap, animatingDifferences: false)
        }
    }
    
    /*
     Searches Spotify global catalogue for songs related to search query
     */
    func searchSpotifyCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {
        guard let devToken = spotifyDevToken else {
            // original development access token probably expired, get new one
            setNewSpotifyAccessToken {
                self.searchSpotifyCatalogue(searchQuery, completionHandler)
            }
            return
        }
        //perform search call
        SpotifyUtilities.searchCatalogue(searchQuery, devToken, completionHandler)
    }
    
    /*
     Searches user's personal Spotify library playlists, and populates into tableview
     */
    func searchSpotifyLibrary() {
        spotifyLibrary.searchPlaylists("", "") {
            // populates results into tableview
            var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
            snap.appendSections(["Playlists"])
            snap.appendItems(self.spotifyLibrary.playlistIDs.map({ (id) -> PlaylistItem in
                PlaylistItem(self.spotifyLibrary.playlistNames[id]!, id)
            }))
            self.parentVC?.datasource.apply(snap, animatingDifferences: false)
        }
    }
    
    //MUST OVERRIDE
    func requestSong() {
        fatalError()
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
