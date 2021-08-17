//
//  BTCommunicationDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//
import CoreBluetooth

protocol BTCommunicationDelegate {
    
    var queueUUID: CBUUID { get }
    var snapshotUUID: CBUUID { get }
        
    var encoder: JSONEncoder { get set }
    var decoder: JSONDecoder { get set }
    
    func updateQueueSnapshot()
    
    func addSongRequest(_ songItem: SongItem, _ completionHandler: @escaping (Error?) -> (), _ deleteSong: Bool)
    func likeSongRequest(_ songURI: String, _ liked: Bool, _ completionHandler: @escaping (Error?) -> ())
    
    func breakConnections()
    
    func openQueue()
    func closeQueue()
}

