//
//  BTHostDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

import CoreBluetooth

class BTHostDelegate: NSObject, BTCommunicationDelegate, CBPeripheralManagerDelegate {

    var queueUUID: CBUUID = CBUUID(string: "E54A93B5-D853-4944-A891-DC63A203379F")
    var snapshotUUID: CBUUID = CBUUID(string: "89957741-008E-4D9D-A6A6-6E95274D05E7")
    
    var snapshotCharacteristic: CBMutableCharacteristic
    
    var peripheralManager: CBPeripheralManager!
    var queueVC: QueueVC
    var connectedCentrals: [CBCentral: String] = [:]
    
    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()
    
    var sentIndex: Int = 0
    var snapshotToSend = Data()
        
    init(_ parentVC: QueueVC) {
        queueVC = parentVC
        var properties: CBCharacteristicProperties = .notify
        properties.formUnion(.read)
        properties.formUnion(.write)
        properties.formUnion(.writeWithoutResponse)
        
        var permissions: CBAttributePermissions = .writeable
        permissions.formUnion(.readable)
        snapshotCharacteristic = CBMutableCharacteristic(type: snapshotUUID, properties: properties, value: nil, permissions: permissions)
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
    }
    
    func closeQueue() {
        peripheralManager.stopAdvertising()
        /*
         TO-DO alert everyone else queue is closed
         */
    }
    
    func openQueue() {
        let username = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
        let queueAd: String = username + " \(queueVC.participants.count) \(queueVC.platform.rawValue)"
        peripheralManager.startAdvertising([CBAdvertisementDataLocalNameKey: queueAd, CBAdvertisementDataServiceUUIDsKey: [queueUUID]])
        /*
         TO-DO alert everyone else queue is open
         */
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheralManager.state {
          case .unknown:
            print("peripheral.state is .unknown")
          case .resetting:
            print("peripheral.state is .resetting")
          case .unsupported:
            print("peripheral.state is .unsupported")
          case .unauthorized:
            print("peripheral.state is .unauthorized")
          case .poweredOff:
            print("peripheral.state is .poweredOff")
          case .poweredOn:
            print("peripheral.state is .poweredOn")
            let service: CBMutableService = CBMutableService(type: queueUUID, primary: true)
            service.characteristics = [snapshotCharacteristic]
            peripheralManager.add(service)
            queueVC.mpDelegate.getQueueSnapshot() { snapshot in
                self.snapshotCharacteristic.value = try? self.encoder.encode(snapshot)
            }
            
            let username = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
            let queueAd: String = username + " \(queueVC.participants.count) \(queueVC.platform.rawValue)"
            peripheral.startAdvertising([CBAdvertisementDataLocalNameKey: queueAd, CBAdvertisementDataServiceUUIDsKey: [queueUUID]])
        @unknown default:
            print("unknown state")
        }
    }
    
    /*
     Participant joined queue
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        updateQueueSnapshot()
        DispatchQueue.main.async {
            self.queueVC.participantMenuVC?.tableView.reloadData()
        }
        for connectedCentral in connectedCentrals.keys {
            if central.identifier == connectedCentral.identifier {
                return
            }
        }
        connectedCentrals[central] = "Joining..."
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        /*
         REMOVE PARTICIPANT FROM CONNECTED CENTRALS LIST AND FROM QUEUE SNAPSHOT
         */
        let participantID: String? = connectedCentrals.removeValue(forKey: central)
        queueVC.participantIDsToUsernames.removeValue(forKey: participantID ?? "")
        let index = queueVC.participants.firstIndex(of: participantID ?? "")
        if let _ = index {
            queueVC.participants.remove(at: index!)
        }
        DispatchQueue.main.async {
            self.queueVC.participantMenuVC?.tableView.reloadData()
        }
        updateQueueSnapshot()
    }
    
    /*
     Respond to read request
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        switch (request.characteristic.uuid) {
        case snapshotUUID:
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.mpDelegate.returnedToApp()
//            }
            print("did receive read request")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.queueVC.mpDelegate.returnedToApp()
            }
            return
        default:
            print("unknown characteristic")
        }
    }
    
    /*
     Respond to write request
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            switch (request.characteristic.uuid) {
            case snapshotUUID:
                let songAdded: CodableSong? = try? decoder.decode(CodableSong.self, from: request.value ?? Data())
                let likedSong: CodableLike? = try? decoder.decode(CodableLike.self, from: request.value ?? Data())
                if likedSong == nil && songAdded == nil {
                    /*
                     Must be username added to participant list
                     */
                    let usernameOrUpdateRequest = try? decoder.decode(String.self, from: request.value ?? Data())
                    guard let newParticipant = usernameOrUpdateRequest else {
                        // or read request...
                        if UIApplication.shared.applicationState == .background {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.queueVC.mpDelegate.returnedToApp()
                            }
                        } else {
                            updateQueueSnapshot()
                        }
                        return
                    }
                    let participantUsername: String = String(newParticipant.split(separator: "\n")[0])
                    let participantUniqueID: String = String(newParticipant.split(separator: "\n")[1])
                    queueVC.participants.append(participantUniqueID)
                    queueVC.participantIDsToUsernames[participantUniqueID] = participantUsername
                    connectedCentrals[request.central] = participantUniqueID
                    peripheral.respond(to: request, withResult: .success)
                    updateQueueSnapshot()
                    DispatchQueue.main.async {
                        self.queueVC.participantMenuVC?.tableView.reloadData()
                    }
                    return
                } else if likedSong != nil {
                    /*
                     Song Like Request
                     */
                    queueVC.mpDelegate.likeSong(likedSong!.uri, likedSong!.liked, likedSong!.likerID)
                    return
                } else {
                    if !songAdded!.add {
                        // delete request, remove from queue
                        queueVC.mpDelegate.deleteSong(songAdded!.uri)
//                        peripheral.respond(to: request, withResult: .success)
                        return
                    }
                    let songItem: SongItem = songAdded!.decodeSong()
                    // request add song to queue
                    queueVC.mpDelegate.addSong(songItem)
                    return
                }
            default:
                print("unknown characteristic")
            }
        }
    }
        
    func updateQueueSnapshot() {
        if BTHostDelegate.refreshingQueue {
            return
        }
        BTHostDelegate.refreshingQueue = true

        queueVC.mpDelegate.getQueueSnapshot { snapshot in
            self.sentIndex = 0
            self.snapshotToSend = try! self.encoder.encode(snapshot)
            self.sendSnapshot()
        }
    }
    
    static var inProgressEOM = false
    static var refreshingQueue = false
    
    private func sendSnapshot() {
        /*
         check if EOM transmission in progress
         */
        if BTHostDelegate.inProgressEOM {
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: snapshotCharacteristic, onSubscribedCentrals: nil)
            if didSend {
                BTHostDelegate.inProgressEOM = false
                sentIndex = 0
                BTHostDelegate.refreshingQueue = false
            }
            // EOM didn't send, wait for peripheralManagerIsReadyToUpdateSubscribers to call sendData again
            return
        }
        
        // anything left to send?
        if sentIndex >= snapshotToSend.count {
            BTHostDelegate.refreshingQueue = false
            return
        }
        
        // There's data left, so send until the callback fails, or we're done.
        var didSend = true
        while didSend {
            
            var amountToSend = snapshotToSend.count - sentIndex
            for central in connectedCentrals.keys {
                if amountToSend > central.maximumUpdateValueLength {
                    amountToSend = central.maximumUpdateValueLength
                }
            }
            
            let subdata = snapshotToSend.subdata(in: sentIndex..<(sentIndex + amountToSend))
            didSend = peripheralManager.updateValue(subdata, for: snapshotCharacteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                return
            }
                        
            sentIndex += amountToSend

            if sentIndex >= snapshotToSend.count {
                BTHostDelegate.inProgressEOM = true
 
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: snapshotCharacteristic, onSubscribedCentrals: nil)

                if eomSent {
                    // It sent; we're all done
                    BTHostDelegate.inProgressEOM = false
                    BTHostDelegate.refreshingQueue = false

                    sentIndex = 0
                }
                return
            }

        }
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendSnapshot()
    }
    
    func addSongRequest(_ songItem: SongItem, _ deleteSong: Bool) {}
    func likeSongRequest(_ songURI: String, _ liked: Bool, _ likerID: String) {}
    
    func breakConnections() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        peripheralManager = nil
        connectedCentrals = [:]
    }
    
}
