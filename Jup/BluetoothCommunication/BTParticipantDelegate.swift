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
    
    var snapshotCharacteristic: CBCharacteristic?

    var centralManager: CBCentralManager!
    var hostPeripheral: CBPeripheral?
    var discoveredQueues: [CBPeripheral] = []
    var discoveredQueueInfo: [CBPeripheral: [String: Any]] = [:]
    var queueVC: QueueVC?
    var participantSettingsVC: ParticipantSettingsVC?
    
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
        print("Disconnected")
        disconnectedFromQueueAlert.message = "App disconnected Bluetooth connection to Queue. Reconnect or return to Settings."
        queueVC?.present(disconnectedFromQueueAlert, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        /*
         Alert user failed to connect, prompt user to reconnect or go back to settings
         */
        print("Failed to connect")
        disconnectedFromQueueAlert.message = "App failed to make Bluetooth connection to Queue. Try again or return to Settings."
        queueVC?.present(disconnectedFromQueueAlert, animated: true)
    }
        
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        for discoveredQueue in discoveredQueues {
            if peripheral.identifier == discoveredQueue.identifier {
                discoveredQueueInfo[peripheral] = advertisementData
                participantSettingsVC?.tableView.reloadData()
                print("reloaded")
                return
            }
        }
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
            if characteristic.uuid == snapshotUUID {
                snapshotCharacteristic = characteristic
                /*
                 Get Updated queue and update queue with name
                 */
                let username = UserDefaults.standard.string(forKey: QueueSettingsVC.usernameKey)
                let usernameData: Data? = try? encoder.encode(username)
                peripheral.writeValue(usernameData ?? Data(), for: snapshotCharacteristic!, type: .withoutResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let _ = error else {
            return
        }
        print("Error: \n\n\(error.debugDescription)")
        completionHandler?()
        completionHandler = nil
    }
      
    var snapshot: Data = Data()
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
            guard let characteristicData = characteristic.value else { return }
            print("Received \(characteristicData.count) bytes")

            if let stringFromData = String(data: characteristicData, encoding: .utf8) {
                // Have we received the end-of-message token?
                if stringFromData == "EOM" {
                    // End-of-message case: show the data.
                    // Dispatch the text view update to the main queue for updating the UI, because
                    // we don't know which thread this method will be called back on.
                    
                    let queueSnapshot: QueueSnapshot? = try? decoder.decode(QueueSnapshot.self, from: snapshot)
                    guard let queue = queueSnapshot else {
                        print("no snapshot")
                        return
                    }
                    print("With: \n\(queue.songs)\n\(queue.state)\n\(queue.timeIn)")
                    queueVC?.mpDelegate.updateQueueWithSnapshot(queue)
                    snapshot = Data()
                    return
                }
            }
            print("Appending \(characteristicData.count) bytes to snapshot data")
            // Otherwise, just append the data to what we have previously received.
            snapshot.append(characteristicData)
            print("Snapshot: \(String(data: snapshot, encoding: .utf8) ?? "Error decoding data")")
        default:
            print("unknown characteristic")
        }
        
    }
    
    func updateQueueSnapshot() {
        /*
         Request to update song
         */
        hostPeripheral?.readValue(for: snapshotCharacteristic!)
//        let updateRequest: Data? = try? encoder.encode("\n\nUPDATE\n\n")
//        hostPeripheral?.writeValue(updateRequest ?? Data(), for: snapshotCharacteristic!, type: .withoutResponse)
    }
    
    /*
     Request to add song
     */
    func requestSong(_ songItem: SongItem, _ completionHandler: @escaping () -> ()) {
        let data = try! encoder.encode(songItem.encodeSong())
        print("Attempting to request song")
        hostPeripheral?.writeValue(data, for: snapshotCharacteristic!, type: .withResponse)
        self.completionHandler = completionHandler
    }
    
    func breakConnections() {
        centralManager!.cancelPeripheralConnection(hostPeripheral!)
        centralManager = nil
        hostPeripheral = nil
        discoveredQueues = []
        discoveredQueueInfo = [:]
    }

}

struct QueueSnapshot: Codable {
    var songs: [CodableSong]
    var timeIn: Int
    var state: Int
    var participants: [String]
    var host: String
}

struct CodableSong: Codable {
    var uri: String
    var artistName: String
    var songTitle: String
    var albumURL: String
    var songLength: UInt
    var platform: Int
    var likes: Int
    var contributor: String
    
    func decodeSong() -> SongItem {
        if Platform(rawValue: platform)! == .APPLE_MUSIC {
            return AppleMusicSongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes, contributor: contributor)
        } else {
            return SpotifySongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes, contributor: contributor)
        }
    }
}
