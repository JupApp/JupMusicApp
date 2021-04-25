//
//  BTParticipantDelegate.swift
//  Jup
//
//  Created by Nick Venanzi on 12/20/20.
//

import CoreBluetooth

class BTParticipantDelegate: NSObject, BTCommunicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate {

    var queueUUID: CBUUID = CBUUID(string: "E54A93B5-D853-4944-A891-DC63A203379F")
    var snapshotUUID: CBUUID = CBUUID(string: "89957741-008E-4D9D-A6A6-6E95274D05E7")
    var participantListUUID: CBUUID = CBUUID(string: "695A3001-B15A-4B1B-8846-349DC262746C")
    
    var snapshotCharacteristic: CBCharacteristic?

    var centralManager: CBCentralManager!
    var hostPeripheral: CBPeripheral?
    var discoveredQueues: [CBPeripheral] = []
    var discoveredQueueInfo: [CBPeripheral: [String: Any]] = [:]
    var queueVC: QueueVC?
    var participantSettingsVC: ParticipantSettingsVC?
    
    var participantsList: ParticipantList = ParticipantList(hostUsername: "", participants: [])
    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()
    
    var completionHandler: (() -> ())?
    
    let disconnectedFromQueueAlert: UIAlertController = UIAlertController(title: "Error connecting to Queue", message: nil, preferredStyle: .alert)
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        disconnectedFromQueueAlert.addAction(UIAlertAction(title: "Reconnect", style: .default, handler: reconnectToQueue))
        disconnectedFromQueueAlert.addAction(UIAlertAction(title: "Return to Settings", style: .cancel, handler: returnToSettings))
    }
    
    func reconnectToQueue(_ alert: UIAlertAction) {
        centralManager.connect(hostPeripheral!, options: nil)
    }
    
    func returnToSettings(_ alert: UIAlertAction) {
        queueVC?.performSegue(withIdentifier: "exitQueue", sender: nil)
    }
    
    func connectToQueue(_ queue: CBPeripheral) {
        centralManager.stopScan()
        queue.delegate = self
        hostPeripheral = queue
        centralManager.connect(queue, options: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
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
            //start scanning baby please
            central.scanForPeripherals(withServices: [queueUUID], options: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("Central is scanning: \(central.isScanning)")
            }
        @unknown default:
            print("unknown state: \(central.state)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // connected to queue
        print("Connected to queue")
        peripheral.discoverServices([queueUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        /*
         Alert user disconnected, prompt user to reconnect or go back to settings
         */
        disconnectedFromQueueAlert.message = "App disconnected Bluetooth connection to Queue. Reconnect or return to Settings."
        queueVC?.present(disconnectedFromQueueAlert, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        /*
         Alert user failed to connect, prompt user to reconnect or go back to settings
         */
        print(error)
        disconnectedFromQueueAlert.message = "App failed to make Bluetooth connection to Queue. Try again or return to Settings."
        queueVC?.present(disconnectedFromQueueAlert, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredQueues.append(peripheral)
        discoveredQueueInfo[peripheral] = advertisementData
        /*
         Update tableview
         */
        print("Found peripheral...adding to tableview")
        participantSettingsVC?.tableView.reloadData()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        print("discovered services")
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            print("discovered characteristic!")
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == participantListUUID {
                /*
                 Add name to participants list
                 */
                let username = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)!
                let participant = ParticipantList(hostUsername: username, participants: [])
                let data = try! encoder.encode(participant)
                peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
            } else if characteristic.uuid == snapshotUUID {
                snapshotCharacteristic = characteristic
                /*
                 Get Updated queue
                 */
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let e = error else {
            return
        }
        completionHandler?()
        completionHandler = nil
    }
        
    /*
     Read in updated queue/participants list data
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        /*
         1. If characteristic is queue, update queue
         2. If characteristic is participant list, update that
         */
        switch (characteristic.uuid) {
        case snapshotUUID:
            print("Snapshot updated")
            guard let data = characteristic.value else {
                /*
                 Will use this to designate the host has left the queue
                 */
                /*
                 ALERT USER
                 */
                return
            }
            peripheral.readValue(for: characteristic)
//            let queueSnapshot: QueueSnapshot = try! decoder.decode(QueueSnapshot.self, from: data)
//            print("With: \n\(queueSnapshot.songs)\n\(queueSnapshot.state)\n\(queueSnapshot.timeRemaining)")
//            queueVC?.mpDelegate.updateQueueWithSnapshot(queueSnapshot)
            return
        case participantListUUID:
            guard let data = characteristic.value else {
                return
            }
            print("Participant list updated")
            participantsList = try! decoder.decode(ParticipantList.self, from: data)

            participantSettingsVC?.tableView.reloadData()
            /*
              Update Side menu list
             */
        default:
            print("unknown characteristic")
        }
        
    }
    
    func updateQueueSnapshot() {
        fatalError("Participant should not be trying to update queue snapshot")
    }
    
    /*
     Request to add song
     */
    func requestSong(_ songItem: SongItem, _ completionHandler: @escaping () -> ()) {
        let data = try! encoder.encode(songItem.encodeSong())
        hostPeripheral?.writeValue(data, for: snapshotCharacteristic!, type: .withResponse)
        self.completionHandler = completionHandler
    }

}

struct ParticipantList: Codable {
    var hostUsername: String
    var participants: [String]
}

struct QueueSnapshot: Codable {
    var songs: [CodableSong]
    var timeRemaining: Int
    var state: Int
}

struct CodableSong: Codable {
    var uri: String
    var artistName: String
    var songTitle: String
    var albumURL: String
    var songLength: UInt
    var platform: Int
    var likes: Int
    
    func decodeSong() -> SongItem {
        if Platform(rawValue: platform)! == .APPLE_MUSIC {
            return AppleMusicSongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes)
        } else {
            return SpotifySongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes)
        }
    }
}
