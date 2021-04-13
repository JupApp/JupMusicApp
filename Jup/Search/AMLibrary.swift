//
//  AMLibrary.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//
import SwiftyJSON
import Foundation

// Class stores information about user's personal playlists
// Caches data on playlists, once playlist is opened, songs within are
// stored and AM request is no longer needed for further calls
class AMLibrary {
        
    // map ID to name
    var playlistNames: [String : String] = [:]
    
    // map ID to playlist content (songs and whatnot)
    var playlistContent: [String : [AppleMusicSongItem]] = [:]
    
    // list of ids in tableview order
    var playlistIDs: [String] = []
    
    func searchPlaylists(_ devToken: String, _ userToken: String, completionHandler: @escaping () -> ()) {
        
        guard playlistIDs.isEmpty else {
            // already searched, just handle completionHandler
            completionHandler()
            return
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.music.apple.com"
        components.path   = "/v1/me/library/playlists"
        components.queryItems = [
            URLQueryItem(name: "limit", value: "100"),
        ]

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
                self.playlistIDs.append(id)
            }
            
            completionHandler()
        }
        task.resume()
    }
    
    /*
     Get Playlist Data given an id and tokens, default calls generic function with offset 0
     */
    func getPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ completionHandler: @escaping () -> ()) {
        getPlaylistData(id, devToken, userToken, "0", completionHandler)
    }
    
    /*
     Get Playlist Data with offset
     */
    func getPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ offset: String, _ completionHandler: @escaping () -> ()) {
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
        helpGetPlaylistData(id, devToken, userToken, request, completionHandler)
    }
    
    /*
     Internal function to get playlist data recursively, 100 songs at a time, takes
     in a url request already made
     */
    func helpGetPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ request: URLRequest, _ completionHandler: @escaping () -> ()) {
        
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
                let songItem = AppleMusicSongItem(id: songID, artist: artistName, song: songTitle, albumURL: newURL, length: songLength)
                self.playlistContent[id]!.append(songItem)
            }
            if !jsonData["next"].exists() {
                completionHandler()
                return
            }
            let path: String = jsonData["next"].stringValue
            guard let index = path.firstIndex(of: "?") else {
                completionHandler()
                return
            }
            let offsetSubstring = path[path.index(index, offsetBy: 8)...]
            let offset = String(offsetSubstring)
            self.getPlaylistData(id, devToken, userToken, offset, completionHandler)
        }
        task.resume()
    }
    
}

