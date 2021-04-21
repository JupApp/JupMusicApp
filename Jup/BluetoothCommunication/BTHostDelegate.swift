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
    var participantListUUID: CBUUID = CBUUID(string: "695A3001-B15A-4B1B-8846-349DC262746C")
    
    var snapshotCharacteristic: CBMutableCharacteristic
    var participantListCharacteristic: CBMutableCharacteristic
    
    var peripheralManager: CBPeripheralManager!
    var queueVC: QueueVC
    var connectedParticipants: [UUID: String] = [:]
    var participantsList: ParticipantList
    
    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()
    
    init(_ parentVC: QueueVC) {
        queueVC = parentVC
        snapshotCharacteristic = CBMutableCharacteristic(type: snapshotUUID, properties: .notify, value: nil, permissions: .writeable)
        participantListCharacteristic = CBMutableCharacteristic(type: participantListUUID, properties: .notify, value: nil, permissions: .writeable)
        let service: CBMutableService = CBMutableService(type: queueUUID, primary: true)
        service.characteristics = [snapshotCharacteristic, participantListCharacteristic]

        let username = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
        participantsList = ParticipantList(hostUsername: username, participants: [])
        
        super.init()
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
        peripheralManager.add(service)
    }

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            
            snapshotCharacteristic.value = try! encoder.encode(queueVC.mpDelegate.getQueueSnapshot())
            
            participantListCharacteristic.value = try! encoder.encode(participantsList)
            
            peripheral.startAdvertising(["Participants": participantsList, "Platform": queueVC.platform.rawValue])
        @unknown default:
            print("unknown state")
        }
    }
    
    func startQueueAdvertising() {
        /*
         TO-DO
         */
    }
    
    func stopQueueAdvertising() {
        /*
         TO-DO
         */
    }
    
    /*
     Participant joined queue
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard characteristic == participantListCharacteristic else {
            return
        }
        print("Central: \(central.identifier) joined the queue!")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard characteristic == participantListCharacteristic else {
            return
        }
        let userLeft: String = connectedParticipants[central.identifier]!
        connectedParticipants.removeValue(forKey: central.identifier)
        print("User: \(userLeft) has left the queue!")
        
        guard let index = participantsList.participants.firstIndex(of: userLeft) else {
            return
        }
        participantsList.participants.remove(at: index)
        /*
         Update participants list accordingly
         */
        participantListCharacteristic.value = try! encoder.encode(participantsList)
    }
    
    /*
     Respond to read request
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        switch (request.characteristic.uuid) {
        case snapshotUUID:
            print("Snapshot read request")
            let snapshotLength: Int = snapshotCharacteristic.value?.count ?? 0
            if (request.offset > snapshotLength) {
                peripheral.respond(to: request, withResult: .invalidOffset)
                return
            }
            let range: Range<Int> = request.offset..<snapshotLength
            request.value = snapshotCharacteristic.value?.subdata(in: range)
            return
        case participantListUUID:
            print("Participant list read request")
            let participantLength: Int = participantListCharacteristic.value?.count ?? 0
            if (request.offset > participantLength) {
                peripheral.respond(to: request, withResult: .invalidOffset)
                return
            }
            let range: Range<Int> = request.offset..<participantLength
            request.value = participantListCharacteristic.value?.subdata(in: range)
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
                print("Snapshot write request")
                let songToAddOrLike: CodableSong? = try? decoder.decode(CodableSong.self, from: request.value ?? Data())
                guard let song = songToAddOrLike else {
                    peripheral.respond(to: request, withResult: .attributeNotFound)
                    return
                }
                let songItem: SongItem = song.decodeSong()
                if songItem.likes == 0 {
                    // request add song to queue
                    queueVC.mpDelegate.addSong(songItem) {
                        // completion handler called implies error
                        peripheral.respond(to: request, withResult: .attributeNotFound)
                    }
                } else {
                    queueVC.mpDelegate.likeSong(songItem.uri, songItem.likes) {
                        // completion handler called implies error
                        peripheral.respond(to: request, withResult: .attributeNotFound)
                    }
                }
                return
            case participantListUUID:
                print("Participant list write request")
                let newParticipant: ParticipantList? = try? decoder.decode(ParticipantList.self, from: request.value ?? Data())
                guard let list = newParticipant else {
                    peripheral.respond(to: request, withResult: .attributeNotFound)
                    return
                }
                let newUser: String = list.hostUsername
                connectedParticipants[request.central.identifier] = newUser
                participantsList.participants.append(newUser)
                participantListCharacteristic.value = try! encoder.encode(participantsList)
                /*
                 Update tableview
                 */
                return
            default:
                print("unknown characteristic")
            }
        }
    }
    
    func updateQueueSnapshot() {
        print("Updated queue snapshot")
        snapshotCharacteristic.value = try! encoder.encode(queueVC.mpDelegate.getQueueSnapshot())
    }
    
    
}
