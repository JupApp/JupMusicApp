import Foundation
import Alamofire
import SwiftyJSON

class SpotifyUtilities {
    
    static var spotifyDevToken: String?
    static var expirationDate: Date?
    
    static var userID: String?
    
    // map ID to name
    static var playlistNames: [String : String] = [:]
    
    // map ID to playlist content (songs and whatnot)
    static var playlistContent: [String : [SpotifySongItem]] = [:]
    
    // list of playlistIDs in order of tableview
    static var playlistIDs: [String] = []
    
    /*
     ###########################################################################################
     ########                                                                           ########
     ########                   LIBRARY FUNCTIONS BELOW                                 ########
     ########                                                                           ########
     ###########################################################################################
     */
    
    /*
     Searches user's personal playlists
     */
    static func searchPlaylists(_ completionHandler: @escaping () -> ()) {
        SpotifyUtilities.checkAuthorization { (authorized) in
            guard authorized else {
                /*
                 Alert user failed to authenticate
                 */
                return
            }
            SpotifyUtilities.retrieveUserID {(id) in
                self.userID = id
                self.searchUsersPlaylists {
                    completionHandler()
                }
            }
        }
        return
    }
    
    /*
     Helper function to retrieve all the different types of personal
     User playlists in spotify
     */
    private static func searchUsersPlaylists(completionHandler: @escaping () -> ()) {
        
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
    private static func getUsersPlaylists(_ offset: Int, _ completionHandler: @escaping () -> ()) {
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
    static func getPlaylistData(_ id: String, _ completionHandler: @escaping () -> ()) {
        guard playlistContent[id] == nil else {
            // songs already loaded for given playlist, return
            completionHandler()
            return
        }
        // set playlist to empty list
        playlistContent[id] = []
        
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
    private static func helperGetPlaylistData(_ id: String, _ offset: Int, _ completionHandler: @escaping () -> ()) {
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
                    playlistContent[id]!.append(songItem)
                }
            }
            /*
             Test update view with each paging
             */
            completionHandler()
            
            // check if another call must be made
            let totalSongs: Int = jsonData["total"].intValue
            if (totalSongs > offset + limit) {
                helperGetPlaylistData(id, offset + limit, completionHandler)
            }
            return
        }
        task.resume()
    }
    
    /*
     Retrieves users top played songs on scale timescale
     */
    private static func getUsersTopPlayedSongs(_ scale: TimeScale, _ offset: Int, _ completionHandler: @escaping () -> ()) {
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
    
    /*
     ###########################################################################################
     ########                                                                           ########
     ########                   CATALOGUE FUNCTIONS BELOW                               ########
     ########                                                                           ########
     ###########################################################################################
     */
    
    /*
     Performs search request on spotify's catalogue for the given searchQuery string
     */
    static func searchCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {
        searchCatalogue(searchQuery, 25, completionHandler)
    }
    
    private static func searchCatalogue(_ searchQuery: String, _ limit: Int, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {

        guard let _ = spotifyDevToken else {
            setNewSpotifyAccessToken { (token) in
                guard let _ = token else { return }
                searchCatalogue(searchQuery, completionHandler)
            }
            return
        }
        
        guard Date(timeIntervalSinceNow: 5) < expirationDate! else {
            // past expiration, renew
            setNewSpotifyAccessToken { (token) in
                guard let _ = token else { return }
                searchCatalogue(searchQuery, completionHandler)
            }
            return
        }

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
        request.setValue("Bearer \(spotifyDevToken!)", forHTTPHeaderField: "Authorization")
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
        let searchQuery: String = SpotifyUtilities.searchQueryFromSong(songItem)
        print("Search Query:\n\(searchQuery)")
        SpotifyUtilities.searchCatalogue(searchQuery) { (possibleMatches) in
            /*
             For now, take first match
             */
            for (i, match) in possibleMatches.enumerated() {
                print("\(i).\t\(match.songTitle): \(match.artistName)")
            }
            guard possibleMatches.count > 0 else {
                completionHandler(nil)
                return
            }
            let songItem: SpotifySongItem = possibleMatches[0]
            songItem.retrieveArtwork { (_) in
                completionHandler(songItem)
            }
        }
        return
    }
    
    /*
     Converts song item into a hierarchy of possible searches to query
     */
    static func searchQueryFromSong(_ songItem: SongItem) -> String {
        let artists: String = songItem.artistName
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "& ", with: "")
            .replacingOccurrences(of: "and ", with: "")
        let title: String = songItem.songTitle
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .replacingOccurrences(of: "- ", with: "")
            .replacingOccurrences(of: "feat. ", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: "& ", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "with ", with: "")
            .replacingOccurrences(of: " x ", with: " ")

        print("Song Title: \n\(title)")
        print("Artists:\n\(artists)")
        return title + " " + artists
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
        guard songDict["album"]["images"].arrayValue.count > 0 else {
            return
        }
        let albumURL: String = songDict["album"]["images"].arrayValue[0]["url"].stringValue

        let songItem = SpotifySongItem(uri: songID, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength)
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
        if expirationDate > Date(timeIntervalSinceNow: 5) {
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
                    guard let _ = userID else {
                        /*
                         Trigger alert that user ID could not be retrieved
                         */
                        return
                    }
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
            print("Authorized: \(authorized)")
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
                print(jsonData)
                let accountStatus = jsonData["product"].stringValue
                print("Account Status: \(accountStatus)")
                guard accountStatus == "premium" else {
                    completionHandler(false)
                    return
                }
                completionHandler(true)
            }
            task.resume()
        }
    }


    /*
     Requests new Authorization token
     */
    static func setNewSpotifyAccessToken(completionHandler: @escaping (String?) -> ()) {
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
                completionHandler(nil)
                return
            }

            // Convert HTTP Response Data to a String
            let jsonData: JSON
            do {try jsonData = JSON(data: data!)} catch{ print("bad data"); return}
            spotifyDevToken = jsonData["access_token"].stringValue
            expirationDate = Date(timeIntervalSinceNow: 3600)
            completionHandler(spotifyDevToken)
        }
        task.resume()
    }
    
    static func clearCache() {
        playlistNames = [:]
        playlistContent = [:]
        playlistIDs = []
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
