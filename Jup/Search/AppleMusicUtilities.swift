//
//  AMCatalogue.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//
import SwiftyJSON
import Security
import StoreKit
import CupertinoJWT


/*
 Class for containing search results information for Apple Music Catalogue queries
 */
class AppleMusicUtilities {
    
    static var amDevToken: String?
    static var devExpirationDate: Date?
    static let amDevTokenKey: String = "amDevTokenKey"
    static let amDevTokenExpKey: String = "amDevTokenExpKey"
    
    static var amUserToken: String?
    
    // map ID to name
    static var playlists: [String : PlaylistItem] = [:]
    
    // map ID to playlist content (songs and whatnot)
    static var playlistContent: [String : [AppleMusicSongItem]] = [:]
    
    // list of ids in tableview order
    static var playlistIDs: [String] = []
    
    static let kid: String = "K2576M4Z3P"
    static let teamID: String = "LT3MWZH387"
        
    static func searchCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([AppleMusicSongItem]) -> ()) {
        guard amDevToken != nil else {
            do {try setNewAMAccessToken { (token) in
                guard let _ = token else { return }
                searchCatalogue(searchQuery, completionHandler)
            } } catch { return }
            return
        }
        
        guard Date(timeIntervalSinceNow: 5) < devExpirationDate! else {
            // past expiration, renew
            do {try setNewAMAccessToken { (token) in
                guard let _ = token else { return }
                searchCatalogue(searchQuery, completionHandler)
            } } catch { return }
            return
        }
        
        let countryCode = "us"

        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.music.apple.com"
        components.path   = "/v1/catalog/\(countryCode)/search"
        components.queryItems = [
            URLQueryItem(name: "term", value: searchQuery),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "types", value: "songs"),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(amDevToken!)", forHTTPHeaderField: "Authorization")
//        let session = URLSession.shared
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {
                try jsonData = JSON(data: dataResponse)
            } catch {
                print("bad data from catalogue request")
                return
            }
            let songDataList: JSON = jsonData["results"]["songs"]["data"]
            
            var searchResults: [AppleMusicSongItem] = []
            
            for songDict in songDataList.arrayValue {
                let songID: String = songDict["id"].stringValue
                let songTitle: String = songDict["attributes"]["name"].stringValue
                let artistName: String = songDict["attributes"]["artistName"].stringValue
                //
                // ########### HARDCODED SIZE TO 300x300 !!!!!!!!! CHANGE
                //
                let artworkURL: String = (songDict["attributes"]["artwork"]["url"].stringValue).replacingOccurrences(of: "{w}x{h}", with: "\(Int(300))x\(Int(300))")
                let songLength: UInt = songDict["attributes"]["durationInMillis"].uIntValue
                
                let username = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
                let songItem = AppleMusicSongItem(id: songID, artist: artistName, song: songTitle, albumURL: artworkURL, length: songLength, contributor: username)
                searchResults.append(songItem)
            }
            completionHandler(searchResults)
        }
        task.resume()
    }
    
    /*
     Attempts to convert song from Spotify Catalogue to Apple Music Catalogue
     */
    static func convertSpotifyToAppleMusic(_ songItem: SongItem, _ completionHandler: @escaping (AppleMusicSongItem?) -> ()) {
        let searchQuery: String = Utilities.searchQueryFromSong(songItem)
        AppleMusicUtilities.searchCatalogue(searchQuery) { (possibleMatches) in
            /*
             For now, take first match
             */
            guard possibleMatches.count > 0 else {
                completionHandler(nil)
                return
            }
            let songItem: AppleMusicSongItem = Utilities.matchQuery(songItem, possibleMatches)
            songItem.retrieveArtwork { (_) in
                completionHandler(songItem)
            }
        }
        return
    }
    
    /*
     Searches user's playlists linked to their account
     */
    static func searchPlaylists(_ completionHandler: @escaping () -> ()) {
        let amDevToken = AppleMusicUtilities.amDevToken
        let expiration = AppleMusicUtilities.devExpirationDate
        let amUserToken = AppleMusicUtilities.amUserToken
        
        guard playlistIDs.isEmpty else {
            // already searched, just handle completionHandler
            completionHandler()
            return
        }

        guard amDevToken != nil &&  Date(timeIntervalSinceNow: 5) < expiration! else {
            do {try AppleMusicUtilities.setNewAMAccessToken { (token) in
                guard let _ = token else { return }
                self.searchPlaylists(completionHandler)
            } } catch { return }
            return
        }

        guard amUserToken != nil else {
            AppleMusicUtilities.setNewUserToken { (token) in
                guard let _ = token else {
                    return
                }
                self.searchPlaylists(completionHandler)
            }
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
        request.setValue("Bearer \(amDevToken!)", forHTTPHeaderField: "Authorization")
        request.setValue(amUserToken!, forHTTPHeaderField: "Music-User-Token")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{
                return
            }

            for playlistDict in jsonData["data"].arrayValue {
                let id = playlistDict["id"].stringValue
                let name = playlistDict["attributes"]["name"].stringValue
                self.playlistIDs.append(id)
                // get album artwork
                let url = playlistDict["attributes"]["artwork"]["url"].stringValue
                let albumURL = url.replacingOccurrences(of: "{w}x{h}", with: "\(Int(400))x\(Int(400))")
                self.playlists[id] = PlaylistItem(name, id, albumURL, .APPLE_MUSIC)
            }
            
            completionHandler()
        }
        task.resume()
    }
    
    /*
     Get Playlist Data given an id and tokens, default calls generic function with offset 0
     */
    static func getPlaylistData(_ id: String, _ completionHandler: @escaping () -> ()) {
        if playlistContent[id]?.isEmpty == false {
            completionHandler()
            return
        }
        getPlaylistData(id, "0", completionHandler)
    }
    
    /*
     Get Playlist Data with offset
     */
    static func getPlaylistData(_ id: String, _ offset: String, _ completionHandler: @escaping () -> ()) {
        let amDevToken = AppleMusicUtilities.amDevToken
        let expiration = AppleMusicUtilities.devExpirationDate
        let amUserToken = AppleMusicUtilities.amUserToken
        
        guard amDevToken != nil &&  Date(timeIntervalSinceNow: 5) < expiration! else {
            do {try AppleMusicUtilities.setNewAMAccessToken { (token) in
                guard let _ = token else { return }
                self.getPlaylistData(id, offset, completionHandler)
            } } catch { return }
            return
        }
        
        guard amUserToken != nil else {
            AppleMusicUtilities.setNewUserToken { (token) in
                guard let _ = token else {
                    return
                }
                self.getPlaylistData(id, offset, completionHandler)
            }
            return
        }
                
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.music.apple.com"
        components.path   = "/v1/me/library/playlists" + "/" + id + "/" + "tracks"
        components.queryItems = [
            URLQueryItem(name: "offset", value: offset),
        ]
        let url = components.url!

        var request = URLRequest(url: url)
        request.setValue("Bearer \(amDevToken!)", forHTTPHeaderField: "Authorization")
        request.setValue(amUserToken!, forHTTPHeaderField: "Music-User-Token")
        helpGetPlaylistData(id, amDevToken!, amUserToken!, request, completionHandler)
    }
    
    /*
     Internal function to get playlist data recursively, 100 songs at a time, takes
     in a url request already made
     */
    private static func helpGetPlaylistData(_ id: String, _ devToken: String, _ userToken: String, _ request: URLRequest, _ completionHandler: @escaping () -> ()) {
        
        if self.playlistContent[id] == nil {
            self.playlistContent[id] = []
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{
                return
            }
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
                // ########### CURRENTLY HARDCODED TO 400x400 !!!!!!!!!
                //
                let newURL = artworkURL.replacingOccurrences(of: "{w}x{h}", with: "\(Int(400))x\(Int(400))")
                
                let songTitle: String = songDictionary["attributes"]["name"].stringValue
                let artistName: String = songDictionary["attributes"]["artistName"].stringValue
                let songLength: UInt = songDictionary["attributes"]["durationInMillis"].uIntValue
                
                let username: String = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
                let songItem = AppleMusicSongItem(id: songID, artist: artistName, song: songTitle, albumURL: newURL, length: songLength, contributor: username)
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
            
            /*
             TEST updating with each call
             */
            completionHandler()

            self.getPlaylistData(id, offset, completionHandler)
        }
        task.resume()
    }
    
    /*
     Creates new Apple Music JWTToken and sets new userToken
     */
    static func setNewAMAccessToken(completionHandler: @escaping (String?) -> ()) throws {
        amDevToken = UserDefaults.standard.string(forKey: amDevTokenKey)
        devExpirationDate = UserDefaults.standard.object(forKey: amDevTokenExpKey) as? Date
        
        guard amDevToken == nil || Date(timeIntervalSinceNow: 5) > devExpirationDate! else {
            completionHandler(amDevToken)
            return
        }
        guard let secret = getAMAuthorizationKey() else {
            return
        }
        let duration: Double = 15777000
        // Assign developer information and token expiration setting
        let jwt = JWT(keyID: kid, teamID: teamID, issueDate: Date(), expireDuration: duration)
        devExpirationDate = Date(timeIntervalSinceNow: duration)
        amDevToken = try jwt.sign(with: secret)
        UserDefaults.standard.setValue(amDevToken, forKey: amDevTokenKey)
        UserDefaults.standard.setValue(devExpirationDate, forKey: amDevTokenExpKey)
        completionHandler(amDevToken)
        return

    }
    
    /*
     Retrieves private authorization key to get developer token
     */
    static func getAMAuthorizationKey() -> String? {
        do {
            guard let path = Bundle.main.path(forResource: "AuthKey_K2576M4Z3P", ofType: ".p8") else {

                return nil
            }
            let fileURL = URL(fileURLWithPath: path);
            let data = try Data(contentsOf: fileURL)
            guard let key = String(data: data, encoding: .utf8) else {
                return nil
            }
            return key
        }
        catch {
            return nil
        }
    }
    
    static func setNewUserToken(_ completionHandler: @escaping (String?) -> ()) {
        do { try setNewAMAccessToken { _ in
            SKCloudServiceController().requestUserToken(forDeveloperToken: amDevToken!) {data, error in
                if let _ = error {
                    print("Error getting user token: \n\(data ?? "")")
                    /*
                     Alert User that app was unable to get user token for AM
                     Probably because user has not authorized this app to use library or
                     user does not have apple ID??
                     */
                    completionHandler(nil)
                    return
                }
                if let token = data {
                    self.amUserToken = token
                    completionHandler(token)
                    return
                }
                completionHandler(nil)
                return
            }
        }
        } catch { completionHandler(nil); return }
    }
    
    static func clearCache() {
        playlists = [:]
        playlistContent = [:]
        playlistIDs = []
    }
}

