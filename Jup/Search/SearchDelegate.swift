//
//  SearchDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

import Foundation
import Security
import StoreKit
import SwiftJWT
import SwiftyJSON


class SearchDelegate {
    
    var amLibrary: AMLibrary = AMLibrary()
    
    var amDevToken: String?
    var amUserToken: String?
    
    var spotifyLibrary: SpotifyLibrary = SpotifyLibrary()
    var spotifyDevToken: String?
    
    let cloudController = SKCloudServiceController()
    var parentVC: SearchVC?
    
    init() {
        
    }
        
    /*
     Searches Apple Music global catalogue for songs related to search query
     */
    func searchAMCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([AppleMusicSongItem]) -> ()) {
        //perform search call
        AppleMusicUtilities.searchCatalogue(searchQuery, completionHandler)
    }
    
    /*
     Searches user's personal Apple Music library playlists, and populates into tableview
     */
    func searchAMLibrary() {
        guard let devToken = amDevToken else {
            // Original Token most likely expired, get new one
            do {try AppleMusicUtilities.setNewAMAccessToken { token in
                guard token != nil else {
                    return
                }
                self.amDevToken = token
                self.searchAMLibrary()
            }} catch {}
            return
        }
        guard let _ = amUserToken else {
            cloudController.requestUserToken(forDeveloperToken: amDevToken!) {data, error in
                if let _ = error {
                    /*
                     Alert User that app was unable to get user token for AM
                     Probably because user has not authorized this app to use library or
                     user does not have apple ID??
                     */
                    return
                }
                if let token = data {
                    self.amUserToken = token
                    self.searchAMLibrary()
                }
                return
            }
            return
        }
        amLibrary.searchPlaylists(devToken, amUserToken!) {
            // populates results into tableview
            var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
            snap.appendSections(["Playlists"])
            snap.appendItems(self.amLibrary.playlistIDs.map({ (id) -> PlaylistItem in
                PlaylistItem(self.amLibrary.playlistNames[id]!, id)
            }))
            self.parentVC?.datasource.apply(snap, animatingDifferences: false)
        }
    }
    
    /*
     Searches Spotify global catalogue for songs related to search query
     */
    func searchSpotifyCatalogue(_ searchQuery: String, _ completionHandler: @escaping ([SpotifySongItem]) -> ()) {
        SpotifyUtilities.searchCatalogue(searchQuery, completionHandler)
    }
    
    /*
     Searches user's personal Spotify library playlists, and populates into tableview
     */
    func searchSpotifyLibrary() {
        spotifyLibrary.searchPlaylists("", "") {
            // populates results into tableview
            var snap = NSDiffableDataSourceSnapshot<String, PlaylistItem>()
            snap.appendSections(["Playlists"])
            snap.appendItems(self.spotifyLibrary.playlistIDs.map({ (id) -> PlaylistItem in
                PlaylistItem(self.spotifyLibrary.playlistNames[id]!, id)
            }))
            self.parentVC?.datasource.apply(snap, animatingDifferences: false)
        }
    }
    
    //MUST OVERRIDE
    func requestSong() {
        fatalError()
    }
    
    
}
