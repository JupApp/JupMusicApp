//
//  SpotifyCatalogue.swift
//  Jup
//
//  Created by Nick Venanzi on 3/23/21.
//

import Foundation
import SwiftyJSON
import Alamofire

class SpotifyCatalogue {
    
    var searchResults: [SongItem] = []
    
    func searchCatalogue(_ searchQuery: String, _ devToken: String) {
        let limit = 25
        AF.request("https://api.spotify.com/v1/search", method: .get, parameters: ["q": searchQuery, "type": "track", "limit": limit], headers: ["Authorization": "Bearer" + " " + devToken]).responseJSON { (data) in
            let response: HTTPURLResponse = data.response!
            print(data.result)

            // if status 4xx
            if "\(response.statusCode)".prefix(1) == "4" {
                /*
                 Trigger alert that song request could not be retrieved
                 */
                return
            }
            switch data.result {
            case .success(let result):
                let songData = ((result as! [String: Any])["tracks"] as! [String: Any])["items"] as! [[String: Any]]
                for songDict in songData {
                    SpotifyUtilities.convertJSONToSongItem(songDict) {songItem in
                        self.searchResults.append(songItem)
                    }
                }
            case .failure(_):
                /*
                Trigger alert that song request could not be retrieved
                */
                return
            }
        }
    }
}
