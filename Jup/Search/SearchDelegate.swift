//
//  SearchDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

import Foundation
import Security


class SearchDelegate {
    
    //TO-DO
    func searchSpotifyCatalogue() {
        
    }
    
    //TO-DO
    func searchAMCatalogue() {
        
    }
    
    //TO-DO
    func searchAMLibrary() {
        let key: String? = getAMAuthorizationKey()
        print(key ?? "Failed to get Key")
    }
    
    //TO-DO
    func searchSpotifyLibrary() {
        
    }
    
    //MUST OVERRIDE
    func requestSong() {
        fatalError()
    }
    
    func getAMAuthorizationKey() -> String? {
        do {
            guard let path = Bundle.main.path(forResource: "AuthKey_5CWA2J2HGK", ofType: ".p8") else {
                return nil
            }
            let fileURL = URL(fileURLWithPath: path);
            let data = try Data(contentsOf: fileURL)
            guard let key = String(data: data, encoding: .utf8) else {
                print("Failed to convert data to string")
                return nil
            }
            return key
        }
        catch {
            return nil
        }
    }
    
    
}
