import Foundation
import Alamofire
import SwiftyJSON

class SpotifyUtilities {
    
    static var spotifyToken: String?
    
    /*
     Performs search request on spotify's catalogue for the given searchQuery string
     */
    static func searchCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {
        searchCatalogue(searchQuery, 25, completionHandler)
    }
    
    private static func searchCatalogue(_ searchQuery: String, _ limit: Int, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {

        guard let _ = spotifyToken else {
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
        request.setValue("Bearer \(spotifyToken!)", forHTTPHeaderField: "Authorization")
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
            spotifyToken = jsonData["access_token"].stringValue
            completionHandler(spotifyToken)
        }
        task.resume()
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
}
