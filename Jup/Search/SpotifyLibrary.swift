//
//  SpotifyLibrary.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//

import SwiftyJSON
import Foundation

// Class stores information about user's personal playlists
// Caches data on playlists, once playlist is opened, songs within are
// stored and Spotify request is no longer needed for further calls
class SpotifyLibrary {
    
    // map ID to name
    var playlistNames: [String : String] = [:]
    
    // map ID to playlist content (songs and whatnot)
    var playlistContent: [String : [SongItem]] = [:]
    
    func searchPlaylists(_ devToken: String, _ userToken: String) {
        checkAuthorization {
            return
        }
        return
        /*
         Add playlist corresponding to user's top played songs (short-term)
         */
        
        /*
         Add playlist corresponding to user's top played songs (medium-term)
         */
        
        /*
         Add playlist corresponding to user's top played songs (long-term)
         */
        
        /*
         Get User's playlists
         */
        
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.music.apple.com"
        components.path   = "/v1/me/library/playlists"

        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            
            for playlistDict in jsonData["data"].arrayValue {
                let id = playlistDict["id"].stringValue
                let name = playlistDict["attributes"]["name"].stringValue
                self.playlistNames[id] = name
                
                
                // THIS IS TEMPORARY, IN FUTURE WE CALL THIS ON A
                // GIVEN PLAYLIST WHEN SELECTED IN SEARCVC TABLEVIEW
                self.getPlaylistData(id, devToken, userToken)
            }
            /*
             UPDATE THE TABLE VIEW ONCE THIS IS COMPLETE
             */
        }
        task.resume()
    }
    
    /*
     Get Playlist Data given an id and tokens, default calls generic function with offset 0
     */
    func getPlaylistData(_ id: String, _ devToken: String, _ userToken: String) {
        getPlaylistData(id, devToken, userToken, "0")
    }
    
    /*
     Get Playlist Data with offset
     */
    func getPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ offset: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.music.apple.com"
        components.path   = "/v1/me/library/playlists" + "/" + id + "/" + "tracks"
        components.queryItems = [
            URLQueryItem(name: "offset", value: offset),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userToken, forHTTPHeaderField: "Music-User-Token")
        helpGetPlaylistData(id, devToken, userToken, request)
    }
    
    /*
     Internal function to get playlist data recursively, 100 songs at a time, takes
     in a url request already made
     */
    func helpGetPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ request: URLRequest) {
        
        if self.playlistContent[id] == nil {
            self.playlistContent[id] = []
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let songListData: JSON = jsonData["data"]
            
            // handle songs
            for (_, songDictionary) in songListData {
                
                // make sure song exists in global Apple Music library
                if !songDictionary["attributes"]["playParams"]["catalogId"].exists() {
                    continue
                }
                // make sure its a song, not music video or whatever
                if songDictionary["attributes"]["playParams"]["kind"].stringValue != "song" {
                    continue
                }
                let songID: String = songDictionary["attributes"]["playParams"]["catalogId"].stringValue
                
                let artworkURL: String = songDictionary["attributes"]["artwork"]["url"].stringValue
                
                //
                // ########### CURRENTLY HARDCODED TO 1200x1200 !!!!!!!!!
                //
                let newURL = artworkURL.replacingOccurrences(of: "{w}x{h}", with: "\(Int(1200))x\(Int(1200))")
                
                let songTitle: String = songDictionary["attributes"]["name"].stringValue
                let artistName: String = songDictionary["attributes"]["artistName"].stringValue
                let songLength: UInt = songDictionary["attributes"]["durationInMillis"].uIntValue
                let songItem: SongItem = AppleMusicSongItem(id: songID, artist: artistName, song: songTitle, albumURL: newURL, length: songLength)
                self.playlistContent[id]!.append(songItem)
            }
            if !jsonData["next"].exists() {
                return
            }
            let path: String = jsonData["next"].stringValue
            guard let index = path.firstIndex(of: "?") else {
                return
            }
            let offsetSubstring = path[path.index(index, offsetBy: 8)...]
            let offset = String(offsetSubstring)
            self.getPlaylistData(id, devToken, userToken, offset)
        }
        task.resume()
    }
    
    func checkAuthorization(completionHandler: @escaping () -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate

        guard let expirationDate = appDelegate.expirationDate as? Date,
              let refreshToken = appDelegate.refreshToken else {
            //must initiate session
            print("must initiate session apparently: \(appDelegate.expirationDate)")
            appDelegate.connectToSpotifyWebAPI {
                // if failed to authenticate, fail silently
                guard let expirationDate = appDelegate.expirationDate as? Date else { return }
                if expirationDate < Date() { return }
                
                print("Returned from connect to spotufy web api")
                print("ExpirationDate: \(appDelegate.expirationDate)")
                print("NewToken: \(appDelegate.accessToken)")
                print("RefreshToken: \(appDelegate.refreshToken)")
                // call check authorization with new tokens, passing in same completionHandler
                print("Trying checkAuthorization again...")
                self.checkAuthorization(completionHandler: completionHandler)
            }
            return
        }
        if expirationDate > Date() {
            // in the clear, don't need to renew yet
            print("in the clear, don't need to renew yet\nTime Remaining: \(Date().distance(to: expirationDate))")
            completionHandler()
            return
        }
        // session expired, renew
        print("token expired, attempt to use manual refresh method")
        
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
    
        let parameters = ["grant_type": "refresh_token", "refresh_token": refreshToken]
        
        // encode parameters into post body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to data object and set it as request body
        } catch let error {
            print("error converting parameters into body")
            return
        }
        
        // set header to encoded client info
        let clientID: String = "93de9a96fb6c4cb39844ac6e98427885"
        let clientSecret: String = "bc693736cf6d40389102d369243384ff"
        let encodedHeader: String = Data("\(clientID):\(clientSecret)".utf8).base64EncodedString()
        request.setValue("Basic \(encodedHeader)", forHTTPHeaderField: "Authorization")
    
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
       
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print("Error in the session reponse of expired session")
                // just renew using SPTSession
                appDelegate.connectToSpotifyWebAPI {
                    self.checkAuthorization(completionHandler: completionHandler)
                }
            } else {
                let httpResponse = response as? HTTPURLResponse
                print("Renew request response: \n\(httpResponse!)")

                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    print(json)
                } catch {
                    print(error)
                }

            }
        })

        dataTask.resume()
        
        // back up:
//        appDelegate.connectToSpotifyWebAPI {
//            print("Access token: \(appDelegate.accessToken)")
//        }
        return
    }
    
}
