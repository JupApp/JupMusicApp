//
//  SpotifyLibrary.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//

import SwiftyJSON
import Foundation
import Alamofire


// Class stores information about user's personal playlists
// Caches data on playlists, once playlist is opened, songs within are
// stored and Spotify request is no longer needed for further calls
class SpotifyLibrary {
    
    var userID: String?
    
    // map ID to name
    var playlistNames: [String : String] = [:]
    
    // map ID to playlist content (songs and whatnot)
    var playlistContent: [String : [SpotifySongItem]] = [:]
    
    // list of playlistIDs in order of tableview
    var playlistIDs: [String] = []
    
    func searchPlaylists(_ devToken: String, _ userToken: String, completionHandler: @escaping () -> ()) {
        SpotifyUtilities.checkAuthorization {
            SpotifyUtilities.retrieveUserID {(id) in
                self.userID = id
                self.searchUsersPlaylists {
                    completionHandler()
                }
            }
        }
        return
    }
    
    
    private func searchUsersPlaylists(completionHandler: @escaping () -> ()) {
        
        guard playlistIDs.isEmpty else {
            completionHandler()
            return
        }
        
        /*
         Add playlist corresponding to user's top played songs (short-term)
         */
        self.playlistNames[TimeScale.SHORT.toString()] = "Top Played Songs (Month)"
        self.playlistIDs.append(TimeScale.SHORT.toString())
        
        /*
         Add playlist corresponding to user's top played songs (medium-term)
         */
        self.playlistNames[TimeScale.MEDIUM.toString()] = "Top Played Songs (Year)"
        self.playlistIDs.append(TimeScale.MEDIUM.toString())

        /*
         Add playlist corresponding to user's top played songs (long-term)
         */
        self.playlistNames[TimeScale.LONG.toString()] = "Top Played Songs (All-Time)"
        self.playlistIDs.append(TimeScale.LONG.toString())

        /*
         Get User's playlists
         */
        self.getUsersPlaylists(0) {
            completionHandler()
        }
        
        /*
         Update table view once these proceses finish
         */
    }
    
    /*
     Retrieves Users personal playlists
     */
    private func getUsersPlaylists(_ offset: Int, _ completionHandler: @escaping () -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let limit: Int = 50
        AF.request("https://api.spotify.com/v1/me/playlists", method: .get, parameters: ["limit": limit, "offset": offset], headers: ["Authorization": "Bearer" + " " + appDelegate.accessToken!]).responseJSON {
            (data) in
                let response: HTTPURLResponse = data.response!
                print(data.result)

                // if status 4xx
                if "\(response.statusCode)".prefix(1) == "4" {
                    /*
                     Trigger alert that user playlists could not be retrieved
                     */
                    return
                }
                switch data.result {
                case .success(let result):
                    guard let playlistData = (result as! [String: Any])["items"] as? [[String: Any]] else {
                        //Returned bad result fail silently
                        return
                    }
                    for playlist in playlistData {
                        let playlistID: String = playlist["id"] as! String
                        let playlistName: String = playlist["name"] as! String
                        self.playlistNames[playlistID] = playlistName
                        self.playlistIDs.append(playlistID)

                    }
                    let totalPlaylists: Int = (result as! [String: Any])["total"] as! Int
                    if (totalPlaylists > offset + limit) {
                        self.getUsersPlaylists(offset + limit, completionHandler)
                        return
                    }
                    completionHandler()
                    return
                case .failure(_):
                    /*
                     Trigger alert that user playlists could not be retrieved
                     */
                    return
                }
        }
    }
    
    /*
     Retrieves Songs from particular playlist
     */
    func getPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ completionHandler: @escaping () -> ()) {
        guard self.playlistContent[id] == nil else {
            // songs already loaded for given playlist, return
            return
        }
        // set playlist to empty list
        self.playlistContent[id] = []
        
        if id == TimeScale.SHORT.toString() {
            // get song info for short term top played songs
            getUsersTopPlayedSongs(.SHORT, 0, completionHandler)
        } else if id == TimeScale.MEDIUM.toString() {
            // get song info for medium term top played songs
            getUsersTopPlayedSongs(.MEDIUM, 0, completionHandler)
        } else if id == TimeScale.LONG.toString() {
            // get song info for short term top played songs
            getUsersTopPlayedSongs(.LONG, 0, completionHandler)
        } else {
            // get song info for input playlist
            helperGetPlaylistData(id, 0, completionHandler)
        }
    }
    
    /*
     Helper to retrieve playlist songs recursively
     */
    private func helperGetPlaylistData(_ id: String, _ offset: Int, _ completionHandler: @escaping () -> ()) {
        let limit = 50
        // get songs for actual playlist in user's profile
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        AF.request("https://api.spotify.com/v1/playlists/\(id)/tracks", method: .get, parameters: ["limit": limit, "offset": offset], headers: ["Authorization": "Bearer" + " " + appDelegate.accessToken!]).responseJSON { (data) in
            let response: HTTPURLResponse = data.response!
            print(data.result)

            // if status 4xx
            if "\(response.statusCode)".prefix(1) == "4" {
                /*
                 Trigger alert that playlist songs could not be retrieved
                 */
                return
            }
            switch data.result {
            case .success(let result):
                guard let songData = (result as! [String: Any])["items"] as? [[String: Any]] else {
                    //Returned bad result fail silently
                    return
                }
                
                for itemDict in songData {
                    guard let songDict = itemDict["track"] as? [String: Any] else {
                        continue
                    }
                    SpotifyUtilities.convertJSONToSongItem(songDict) {songItem in
                        self.playlistContent[id]!.append(songItem)
                    }
                }
                
                // check if another call must be made
                let totalSongs: Int = (result as! [String: Any])["total"] as! Int
                if (totalSongs > offset + limit) {
                    self.helperGetPlaylistData(id, offset + limit, completionHandler)
                    return
                }
                completionHandler()
                return
            case .failure(_):
                /*
                 Trigger alert that user playlists could not be retrieved
                 */
                return
            }

        }
    }
    
    
    /*
     Retrieves users top played songs on scale timescale
     */
    private func getUsersTopPlayedSongs(_ scale: TimeScale, _ offset: Int, _ completionHandler: @escaping () -> ()) {
        let limit = 50
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        AF.request("https://api.spotify.com/v1/me/top/songs", method: .get, parameters: ["time_range": scale.toString(), "limit": limit, "offset": offset], headers: ["Authorization": "Bearer" + " " + appDelegate.accessToken!]).responseJSON { (data) in
            let response: HTTPURLResponse = data.response!
            print(data.result)

            // if status 4xx
            if "\(response.statusCode)".prefix(1) == "4" {
                /*
                 Trigger alert that user top played songs could not be retrieved
                 */
                return
            }
            switch data.result {
            case .success(let result):
                guard let songData = (result as! [String: Any])["items"] as? [[String: Any]] else {
                    //Returned bad result fail silently
                    return
                }
                
                for songDict in songData {
                    SpotifyUtilities.convertJSONToSongItem(songDict) {songItem in
                        self.playlistContent[scale.toString()]!.append(songItem)
                    }
                }
                
                // check if another call must be made
                let totalSongs: Int = (result as! [String: Any])["total"] as! Int
                if (totalSongs > offset + limit) {
                    self.getUsersTopPlayedSongs(scale, offset + limit, completionHandler)
                    return
                }
                completionHandler()
                return
            case .failure(_):
                /*
                 Trigger alert that user playlists could not be retrieved
                 */
                return
            }

        }
    }

}

enum TimeScale {
    case SHORT
    case MEDIUM
    case LONG
    
    func toString() -> String {
        switch (self) {
        case .SHORT: return "short_term"
        case .MEDIUM: return "medium_term"
        case .LONG: return "long_term"
        }
    }
}
