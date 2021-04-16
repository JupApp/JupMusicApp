//
//  SpotifyUtilities.swift
//  Jup
//
//  Created by Nick Venanzi on 4/12/21.
//

import Foundation
import Alamofire
import SwiftyJSON

class SpotifyUtilities {
    
    /*
     Performs search request on spotify's catalogue for the given searchQuery string
     */
    static func searchCatalogue(_ searchQuery: String, _ devToken: String, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {
        let limit = 25
        
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.spotify.com"
        components.path   = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            var searchResults: [SpotifySongItem] = []
            
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let songData = jsonData["tracks"]["items"].arrayValue
            for songDict in songData {
                SpotifyUtilities.convertJSONToSongItem(songDict) {songItem in
                    searchResults.append(songItem)
                }
            }
            completionHandler(searchResults)
        }
        task.resume()
    }
    
    /*
     Attempts to convert AM song to Spotify song
     */
    static func convertAppleMusicToSpotify(_ songItem: SongItem, _ completionHandler: @escaping (SpotifySongItem?) -> ()) {
        /*
         To - Do
         */
        fatalError("Have not implemented conversion function yet.")
    }
    
    /*
     Helper function to take in SwiftyJSON item and parse into SongItem
     */
    static func convertJSONToSongItem(_ songDict: JSON, completionHandler: @escaping (SpotifySongItem) -> ()) {
        let songID: String = songDict["uri"].stringValue

        // filter out local tracks
        guard songID.split(separator: ":")[1] != "local" else {
            return
        }
        let songTitle: String = songDict["name"].stringValue

        /*
        get artists into string form
        */
        var artists: [String] = []
        for artistDict in songDict["artists"].arrayValue {
            artists.append(artistDict["name"].stringValue)
        }
        var artistName: String = ""
        if artists.count == 1 {
            artistName = artists[0]
        } else if artists.count == 2 {
            artistName = artists[0] + " and " + artists[1]
        } else if artists.count > 2 {
            for artist in artists[..<(artists.count-1)] {
                artistName += artist + ", "
            }
            artistName += "and " + artists[artists.count-1]
        }

        let songLength: UInt = songDict["duration_ms"].uIntValue

        /*
         Retrieves 640x640 image for album. Index 1 is 300x300, Index 2 is 64x64
         */
        let albumURL: String = songDict["album"]["images"].arrayValue[0]["url"].stringValue

        let songItem = SpotifySongItem(uri: songID, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength)
//        songItem.retrieveArtwork { (_) in }
        completionHandler(songItem)
    }
    
    /*
     Helper function to check to make sure access token hasn't expired and app
     has user authentication to search their playlists
     */
    static func checkAuthorization(completionHandler: @escaping (Bool) -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        // check if refresh token doesn't exist
        guard let expirationDate = appDelegate.expirationDate as? Date,
              let refreshToken = appDelegate.refreshToken else {

            //must initiate session for first time
            appDelegate.connectToSpotify {e in

                if let _ = e {
                    completionHandler(false)
                }
                // otherwise, successfully connected to spotify, and ready to go!
                completionHandler(true)
            }
            return
        }

        // check if expiration date is already passed
        if expirationDate > Date() {
            // in the clear, don't need to renew yet
            completionHandler(true)
            return
        }
        
        // session expired, try to use refresh token to get new token
        AF.request("https://jup-music-queue.herokuapp.com/api/refresh_token", method: .post, parameters: ["refresh_token": refreshToken]).responseJSON { (data) in
            let response: HTTPURLResponse = data.response!

            // if status 4xx
            if "\(response.statusCode)".prefix(1) == "4" {
                // just reinitiate session...
                appDelegate.connectToSpotify {e in

                    if let _ = e {
                        completionHandler(false)
                        return
                    }
                    // otherwise, successfully connected to spotify, and ready to go!
                    completionHandler(true)
                }
                return

            } else {
                switch data.result {
                case .success(let result):
                    let access_token: String = (result as! [String: Any])["access_token"] as! String
                    appDelegate.accessToken = access_token
                    completionHandler(true)
                    return
                case .failure(_):
                    appDelegate.connectToSpotify {e in

                        if let _ = e {
                            completionHandler(false)
                            return
                        }
                        // otherwise, successfully connected to spotify, and ready to go!
                        completionHandler(true)
                    }
                    return
                }
            }
        }
        return
    }
    
    /*
     Retrieve userID for user, needed to complete web api calls to users libraries
     */
    static func retrieveUserID(completionHandler: @escaping (String) -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        print("Retrieving User ID with \(appDelegate.accessToken!)")
        
        AF.request("https://api.spotify.com/v1/me", method: .get, headers: ["Authorization": "Bearer" + " " + appDelegate.accessToken!]).responseJSON {
            (data) in
                let response: HTTPURLResponse = data.response!
                print(data.result)

                // if status 4xx
                if "\(response.statusCode)".prefix(1) == "4" {
                    /*
                     Trigger alert that user ID could not be retrieved
                     */
                    return
                }
                switch data.result {
                case .success(let result):
                    let userID = (result as! [String: Any])["id"] as? String
                    completionHandler(userID!)
                    return
                case .failure(_):
                    /*
                     Trigger alert that user ID could not be retrieved
                     */
                    return
                }
        }
    }
    
    /*
     Determines if user has Spotify Premium
     */
    static func doesHavePremium(_ completionHandler: @escaping (Bool) -> ()) {
        checkAuthorization { (authorized) in
            guard authorized else {
                completionHandler(false)
                return
            }
            
            // proceed to request if premium account is active
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            var components = URLComponents()
            components.scheme = "https"
            components.host   = "api.spotify.com"
            components.path   = "/v1/me"
            let url = components.url!

            var request = URLRequest(url: url)
            request.setValue("Bearer \(appDelegate.accessToken!)", forHTTPHeaderField: "Authorization")
            let session = URLSession.shared
            let task = session.dataTask(with: request) { data, response, error in
                guard let dataResponse = data else {
                    return
                }
                let jsonData: JSON
                do {try jsonData = JSON(data: dataResponse)} catch{ completionHandler(false); return}
                let accountStatus = jsonData["product"].stringValue
                guard accountStatus == "premium" else {
                    completionHandler(false)
                    return
                }
                completionHandler(true)
            }
            task.resume()
        }
    }
}
