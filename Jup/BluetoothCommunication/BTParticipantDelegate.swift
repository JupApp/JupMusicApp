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
    var discoveredQueueInfo: [CBPeripheral: QueueInfo] = [:]
    var queueVC: QueueVC?
    var settingsVC: SettingsVC?
    
    var encoder: JSONEncoder = JSONEncoder()
    var decoder: JSONDecoder = JSONDecoder()
    
    var completionHandler: ((Error?) -> ())?
    
    let disconnectedFromQueueAlert: UIAlertController = UIAlertController(title: "Error connecting to Queue", message: nil, preferredStyle: .alert)
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        disconnectedFromQueueAlert.addAction(UIAlertAction(title: "Return to Settings", style: .default, handler: returnToSettings))
    }
    
    func returnToSettings(_ alert: UIAlertAction) {
        queueVC?.mpDelegate = nil
        queueVC?.performSegue(withIdentifier: "exitQueue", sender: nil)
        queueVC = nil
    }
    
    func connectToQueue(_ queue: CBPeripheral) {
        centralManager.stopScan()
        queue.delegate = self
        hostPeripheral = queue
        centralManager.connect(queue, options: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .poweredOn:
            print("central.state is .poweredOn")
            //start scanning baby please
            guard hostPeripheral == nil else {
                return
            }
            central.scanForPeripherals(withServices: [queueUUID], options: nil)
          default:
            let alert = UIAlertController(title: "Bluetooth", message: "Turn on BlueTooth in order to utilize music queues.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            if let _ = queueVC {
                queueVC?.present(alert, animated: true)
            } else if let _ = settingsVC {
                settingsVC?.present(alert, animated: true)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // connected to queue
        peripheral.discoverServices([queueUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        /*
         Alert user disconnected, prompt user to reconnect or go back to settings
         */
        print("Timer fire date: \(queueVC?.mpDelegate.songTimer?.fireDate ?? Date.distantFuture)")
        queueVC?.mpDelegate.songTimer?.invalidate()
        print("Timer cancelled...?")
        disconnectedFromQueueAlert.message = "App disconnected Bluetooth connection to Queue. Return to Settings."
        queueVC?.present(disconnectedFromQueueAlert, animated: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        /*
         Alert user failed to connect, prompt user to reconnect or go back to settings
         */
        disconnectedFromQueueAlert.message = "App failed to make Bluetooth connection to Queue. Return to Settings."
        queueVC?.present(disconnectedFromQueueAlert, animated: true)
    }
    
    
        
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // first check if advertisement data is there
        guard let hostInfo = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
            return
        }
        var hostPieces: [String] = hostInfo.split(separator: " ").map { String($0) }
        
        let platform: Platform
        let numParticipants: Int
        let hostName: String
        
        if hostPieces.count > 2 {
            numParticipants = Int(hostPieces.removeLast()) ?? 1
        } else {
            numParticipants = 1
        }
        
        if hostPieces.count > 1 {
            hostName = hostPieces.removeLast().replacingOccurrences(of: "_", with: " ")
        } else {
            hostName = "Unknown"
        }
        
        if hostPieces.count > 0 {
            platform = Platform(rawValue: Int(hostPieces.removeLast()) ?? 0)!
        } else {
            /*
             Display host found, but unable to configure a connection. Host device battery may be low.  Restart app and try again
             */
            return
        }
        
        let queueInfo: QueueInfo = QueueInfo(hostname: hostName, platform: platform, numParticipants: numParticipants)
        
        for discoveredQueue in discoveredQueues {
            if peripheral.identifier == discoveredQueue.identifier {
                discoveredQueueInfo[peripheral] = queueInfo
                settingsVC?.queueTableView.reloadData()
                return
            }
        }
        discoveredQueues.append(peripheral)
        discoveredQueueInfo[peripheral] = queueInfo
        /*
         Update tableview
         */
        settingsVC?.queueTableView.reloadData()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics! {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.uuid == snapshotUUID {
                snapshotCharacteristic = characteristic
                /*
                 Get Updated queue and update queue with name
                 */
                let username = UserDefaults.standard.string(forKey: SettingsVC.usernameKey)!
                let uniqueID = UIDevice.current.identifierForVendor!.uuidString
                let usernameData: Data? = try? encoder.encode(username + "\n" + uniqueID)
                peripheral.writeValue(usernameData ?? Data(), for: snapshotCharacteristic!, type: .withoutResponse)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        guard let _ = error else {
//            completionHandler?(nil)
//            return
//        }
//        completionHandler?(AddSongError())
//        completionHandler = nil
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
            guard let characteristicData = characteristic.value else { return }

            if let stringFromData = String(data: characteristicData, encoding: .utf8) {
                if stringFromData == "START" {
                    snapshot = Data()
                    return
                }
                // Have we received the end-of-message token?
                if stringFromData == "EOM" {
                    // End-of-message case: show the data.
                    // Dispatch the text view update to the main queue for updating the UI, because
                    // we don't know which thread this method will be called back on.
                    
                    let queueSnapshot: QueueSnapshot? = try? decoder.decode(QueueSnapshot.self, from: snapshot)
                    guard let queue = queueSnapshot else {
                        snapshot = Data()
                        return
                    }
                    queueVC?.participantIDsToUsernames = queue.participantMap
                    queueVC?.mpDelegate.updateQueueWithSnapshot(queue)
                    queueVC?.settings = queue.settings
                    snapshot = Data()
                    return
                }
            }
            // Otherwise, just append the data to what we have previously received.
            snapshot.append(characteristicData)
        default:
            print("unknown characteristic")
        }
        
    }
    
    func updateQueueSnapshot() {
        /*
         Request to update song
         */
        print("requesting song update")
        hostPeripheral?.writeValue(Data(), for: snapshotCharacteristic!, type: .withoutResponse)

    }
    
    /*
     Request to add song
     */
    func addSongRequest(_ songItem: SongItem, _ deleteSong: Bool) {
        let encodedSong = deleteSong ? songItem.encodeSong(false) : songItem.encodeSong()
        let data = try! encoder.encode(encodedSong)
        hostPeripheral?.writeValue(data, for: snapshotCharacteristic!, type: .withoutResponse)
    }
    
    /*
     Request to like Song
     */
    func likeSongRequest(_ songURI: String, _ liked: Bool, _ likerID: String) {
        let codableLike: CodableLike = CodableLike(uri: songURI, liked: liked, likerID: likerID)
        let data = try! encoder.encode(codableLike)
        hostPeripheral?.writeValue(data, for: snapshotCharacteristic!, type: .withoutResponse)
    }
    
    func breakConnections() {
        if let _ = hostPeripheral {
            centralManager?.cancelPeripheralConnection(hostPeripheral!)
        }
        hostPeripheral = nil
        discoveredQueues = []
        discoveredQueueInfo = [:]
    }
    
    func openQueue() {}
    func closeQueue() {}

}

struct QueueInfo {
    var hostname: String
    var platform: Platform
    var numParticipants: Int
}

struct QueueSnapshot: Codable {
    var songs: [CodableSong]
    var timeIn: Double
    var state: Int
    var participants: [String]
    var settings: Settings
    var participantMap: [String: String]
}

struct Settings: Codable {
    var queueOpen: Bool
    var hostEditingOn: Bool
    var selfLikingOn: Bool
}

struct CodableLike: Codable {
    var uri: String
    var liked: Bool
    var likerID: String
}

struct CodableSong: Codable {
    var uri: String
    var artistName: String
    var songTitle: String
    var albumURL: String
    var songLength: UInt
    var platform: Int
    var likes: Set<String>
    var contributor: String
    var timeAdded: Date
    var add: Bool
    
    func decodeSong() -> SongItem {
        if Platform(rawValue: platform)! == .APPLE_MUSIC {
            return AppleMusicSongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes, contributor: contributor, timeAdded: timeAdded)
        } else {
            return SpotifySongItem(id: uri, artist: artistName, song: songTitle, albumURL: albumURL, length: songLength, likes: likes, contributor: contributor, timeAdded: timeAdded)
        }
    }
}
