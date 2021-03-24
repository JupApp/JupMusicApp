//
//  AMCatalogue.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//
import SwiftyJSON

/*
 Class for containing search results information for Apple Music Catalogue queries
 */
class AMCatalogue {
    
    var searchResults: [SongItem] = []
    
    func searchCatalogue(_ searchQuery: String, _ devToken: String) {
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
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let songDataList: JSON = jsonData["results"]["songs"]["data"]
            
            for songDict in songDataList.arrayValue {
                let songID: String = songDict["id"].stringValue
                let songTitle: String = songDict["attributes"]["name"].stringValue
                let artistName: String = songDict["attributes"]["artistName"].stringValue
                //
                // ########### HARDCODED SIZE TO 1200x1200 !!!!!!!!! CHANGE
                //
                let artworkURL: String = (songDict["attributes"]["artwork"]["url"].stringValue).replacingOccurrences(of: "{w}x{h}", with: "\(Int(1200))x\(Int(1200))")
                let songLength: UInt = songDict["attributes"]["durationInMillis"].uIntValue
                
                let songItem = AppleMusicSongItem(id: songID, artist: artistName, song: songTitle, albumURL: artworkURL, length: songLength)
                songItem.retrieveArtwork { (_) in
                    // add song item to table once artwork is retrieved
                    self.searchResults.append(songItem)
                    //
                    //DO ANY NECESSARY CALL TO UPDATE TABLE
                    //
                }
            }
        }
        task.resume()
    }
    
}
