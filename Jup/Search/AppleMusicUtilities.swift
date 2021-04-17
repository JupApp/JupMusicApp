//
//  AMCatalogue.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//
import SwiftyJSON
import Security
import StoreKit
import SwiftJWT

/*
 Class for containing search results information for Apple Music Catalogue queries
 */
class AppleMusicUtilities {
    
    static var amToken: String?
        
    static func searchCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([AppleMusicSongItem]) -> ()) {
        if amToken == nil {
            do {try setNewAMAccessToken { (token) in
                guard let _ = token else { return }
                searchCatalogue(searchQuery, completionHandler)
            } } catch { return }
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
        request.setValue("Bearer \(amToken!)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
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
                
                let songItem = AppleMusicSongItem(id: songID, artist: artistName, song: songTitle, albumURL: artworkURL, length: songLength)
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
        let searchQuery: String = SpotifyUtilities.searchQueryFromSong(songItem)
        AppleMusicUtilities.searchCatalogue(searchQuery) { (possibleMatches) in
            /*
             For now, take first match
             */
            guard possibleMatches.count > 0 else {
                completionHandler(nil)
                return
            }
            let songItem: AppleMusicSongItem = possibleMatches[0]
            songItem.retrieveArtwork { (_) in
                completionHandler(songItem)
            }
        }
        return
    }
    
    /*
     Creates new Apple Music JWTToken and sets new userToken
     */
    static func setNewAMAccessToken(completionHandler: @escaping (String?) -> ()) throws {
        guard amToken == nil else {
            completionHandler(amToken)
            return
        }
        guard let privateKey = getAMAuthorizationKey() else {
            return
        }
        let keyData = privateKey.data(using: .utf8)!
        let kid = "5CWA2J2HGK"
        let myHeader = Header(kid: kid)
        
        let iss = "LT3MWZH387"
        let now = Date(timeIntervalSinceNow: 0)
        let exp = Date(timeIntervalSinceNow: 1100)
        
        let myClaims = ClaimsStandardJWT(iss: iss, exp: exp, iat: now)
        var myJWT = JWT(header: myHeader, claims: myClaims)
        let myJWTSigner = JWTSigner.es256(privateKey: keyData)
        amToken = try myJWT.sign(using: myJWTSigner)
        completionHandler(amToken)
    }
    
    /*
     Retrieves private authorization key to get developer token
     */
    static func getAMAuthorizationKey() -> String? {
        do {
            guard let path = Bundle.main.path(forResource: "AuthKey_5CWA2J2HGK", ofType: ".p8") else {
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
    
    static func checkAuthorization(_ completionHandler: @escaping () -> ()) {
        
    }
    
}
