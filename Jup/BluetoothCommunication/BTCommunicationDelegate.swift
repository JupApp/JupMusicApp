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
    var participantListUUID: CBUUID { get }
}

