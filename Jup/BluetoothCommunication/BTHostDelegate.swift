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
    var queueVC: QueueVC?
    var connectedParticipants: [UUID] = []
    
    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()
    
    override init() {
        snapshotCharacteristic = CBMutableCharacteristic(type: snapshotUUID, properties: .notify, value: nil, permissions: .writeable)
        participantListCharacteristic = CBMutableCharacteristic(type: participantListUUID, properties: .notify, value: nil, permissions: .writeable)
        let service: CBMutableService = CBMutableService(type: queueUUID, primary: true)
        service.characteristics = [snapshotCharacteristic, participantListCharacteristic]

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
            
            snapshotCharacteristic.value = try! encoder.encode(queueVC!.mpDelegate.getQueueSnapshot())
            
            let username = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
            participantListCharacteristic.value = try! encoder.encode(Participant(username: username))
            
            peripheral.startAdvertising(["Host": username, "Platform": queueVC!.platform.rawValue])
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
        if !connectedParticipants.contains(central.identifier) {
            connectedParticipants.append(central.identifier)
            print("Central: \(central.identifier) joined the queue!")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard characteristic == participantListCharacteristic else {
            return
        }
        guard let index = connectedParticipants.firstIndex(of: central.identifier) else {
            return
        }
        print("Central: \(central.identifier) has left the queue!")
        connectedParticipants.remove(at: index)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        
    }
    
    
}
