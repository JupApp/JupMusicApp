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
     Helper function to take in SwiftyJSON item and parse into SongItem
     */
    static func convertJSONToSongItem(_ songDict: JSON, completionHandler: @escaping (SpotifySongItem) -> ()) {
        let songID: String = songDict["uri"].stringValue
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
    static func checkAuthorization(completionHandler: @escaping () -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        // check if refresh token doesn't exist
        guard let expirationDate = appDelegate.expirationDate as? Date,
              let refreshToken = appDelegate.refreshToken else {

            //must initiate session for first time
            appDelegate.connectToSpotify {e in

                if let error = e {
                    print("error connecting to spotify:\n\n\(error)")
                    /*
                     TO-DO, trigger alert for if this fails
                     */
                    return
                }
                // otherwise, successfully connected to spotify, and ready to go!
                completionHandler()
            }
            return
        }

        // check if expiration date is already passed
        if expirationDate > Date() {
            // in the clear, don't need to renew yet
            print("in the clear, don't need to renew yet\nTime Remaining: \(Date().distance(to: expirationDate))")
            completionHandler()
            return
        }

        print("Need to refresh access_token")
        // session expired, try to use refresh token to get new token

        AF.request("https://jup-music-queue.herokuapp.com/api/refresh_token", method: .post, parameters: ["refresh_token": refreshToken]).responseJSON { (data) in
            let response: HTTPURLResponse = data.response!
            
            // if status 4xx
            if "\(response.statusCode)".prefix(1) == "4" {
                // just reinitiate session...
                print("Failed to sneaky refresh, just re initiate session")
                appDelegate.connectToSpotify {e in
                    
                    if let error = e {
                        print("error connecting to spotify:\n\n\(error)")
                        /*
                         TO-DO, trigger alert for if this fails
                         */
                        return
                    }
                    // otherwise, successfully connected to spotify, and ready to go!
                    completionHandler()
                }
                return
                
            } else {
                print(data.result)
                switch data.result {
                case .success(let result):
                    let access_token: String = (result as! [String: Any])["access_token"] as! String
                    appDelegate.accessToken = access_token
                    completionHandler()
                    return
                case .failure(_):
                    appDelegate.connectToSpotify {e in
                        
                        if let error = e {
                            print("error connecting to spotify:\n\n\(error)")
                            /*
                             TO-DO, trigger alert for if this fails
                             */
                            return
                        }
                        // otherwise, successfully connected to spotify, and ready to go!
                        completionHandler()
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
}
