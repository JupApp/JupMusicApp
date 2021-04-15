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
    
    var searchResults: [SpotifySongItem] = []
    
    func searchCatalogue(_ searchQuery: String, _ devToken: String, _ completionHandler: @escaping () -> ()) {
        let limit = 25
        
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
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let dataResponse = data else {
                return
            }
            let jsonData: JSON
            do {try jsonData = JSON(data: dataResponse)} catch{ print("bad data"); return}
            let songData = jsonData["tracks"]["items"].arrayValue
            for songDict in songData {
                SpotifyUtilities.convertJSONToSongItem(songDict) {songItem in
                    self.searchResults.append(songItem)
                }
            }
            completionHandler()
        }
        task.resume()
    }
}
