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
    }
    
    /*
     Retrieves Users personal playlists
     */
    private func getUsersPlaylists(_ offset: Int, _ completionHandler: @escaping () -> ()) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let limit: Int = 50
        
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.spotify.com"
        components.path   = "/v1/me/playlists"
        components.queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(appDelegate.accessToken!)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let playlistData = jsonData["items"].arrayValue
            for playlist in playlistData {
                let playlistID: String = playlist["id"].stringValue
                let playlistName: String = playlist["name"].stringValue
                self.playlistNames[playlistID] = playlistName
                self.playlistIDs.append(playlistID)
            }
            let totalPlaylists: Int = jsonData["total"].intValue
            if (totalPlaylists > offset + limit) {
                self.getUsersPlaylists(offset + limit, completionHandler)
            }
            completionHandler()
            return
        }
        task.resume()
    }
    
    /*
     Retrieves Songs from particular playlist
     */
    func getPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ completionHandler: @escaping () -> ()) {
        guard self.playlistContent[id] == nil else {
            // songs already loaded for given playlist, return
            completionHandler()
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
        
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.spotify.com"
        components.path   = "/v1/playlists/\(id)/tracks"
        components.queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(appDelegate.accessToken!)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let songData = jsonData["items"].arrayValue
            for songDict in songData {
                SpotifyUtilities.convertJSONToSongItem(songDict["track"]) {songItem in
                    self.playlistContent[id]!.append(songItem)
                }
            }
            /*
             Test update view with each paging
             */
            completionHandler()
            
            // check if another call must be made
            let totalSongs: Int = jsonData["total"].intValue
            if (totalSongs > offset + limit) {
                self.helperGetPlaylistData(id, offset + limit, completionHandler)
            }
            return
        }
        task.resume()
    }
    
    
    /*
     Retrieves users top played songs on scale timescale
     */
    private func getUsersTopPlayedSongs(_ scale: TimeScale, _ offset: Int, _ completionHandler: @escaping () -> ()) {
        let limit = 50
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.spotify.com"
        components.path   = "/v1/me/top/tracks"
        components.queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "time_range", value: scale.toString()),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(appDelegate.accessToken!)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let songData = jsonData["items"].arrayValue
            for songDict in songData {
                SpotifyUtilities.convertJSONToSongItem(songDict) {songItem in
                    self.playlistContent[scale.toString()]!.append(songItem)
                }
            }
            /*
             Test update view with each paging
             */
            completionHandler()
            
            // check if another call must be made
            let totalSongs: Int = jsonData["total"].intValue
            if (totalSongs > offset + limit) {
                self.getUsersTopPlayedSongs(scale, offset + limit, completionHandler)
            }
            return
        }
        task.resume()
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
