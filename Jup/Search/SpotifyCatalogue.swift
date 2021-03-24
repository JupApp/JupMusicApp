//
//  SpotifyCatalogue.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//

import Foundation
import SwiftyJSON

class SpotifyCatalogue {
    
    var searchResults: [SongItem] = []
    
    func searchCatalogue(_ searchQuery: String, _ devToken: String) {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.spotify.com"
        components.path   = "/v1/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: searchQuery),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "25"),
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
            let songDataList: JSON = jsonData["tracks"]["items"]
            
            // loop through each songDict
            for songDict in songDataList.arrayValue {
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
                let albumURL: String = songDict["album"]["images"][0]["url"].stringValue
                
                let songItem = SpotifySongItem(uri: songID, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength)
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
