//
//  SearchDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

protocol SearchDelegate {
        
    /*
     Searches Apple Music global catalogue for songs related to search query and populates into songList tableView
     */
    func searchAMCatalogue(_ searchQuery: String, _ songListVC: SongListVC<AppleMusicSongItem>)
    
    /*
     Searches user's personal Apple Music library playlists, and populates into tableview
     */
    func searchAMLibrary()
    
    /*
     Searches AM Playlist Contents and populates into songList tableView
     */
    func searchAMPlaylist(_ playlistID: String, _ songListVC: SongListVC<AppleMusicSongItem>)
    
    /*
     Searches Spotify global catalogue for songs related to search query and populates into songList tableView
     */
    func searchSpotifyCatalogue(_ searchQuery: String, _ songListVC: SongListVC<SpotifySongItem>)
    
    /*
     Searches user's personal Spotify library playlists, and populates into tableview
     */
    func searchSpotifyLibrary()
    
    /*
     Searches Spotify Playlist Contents and populates into songList tableView
     */
    func searchSpotifyPlaylist(_ playlistID: String, _ songListVC: SongListVC<SpotifySongItem>)
    
}
