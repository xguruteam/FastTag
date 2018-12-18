//
//  ViewController.swift
//  Fast Tag
//
//  Created by Guru on 12/6/18.
//  Copyright © 2018 Guru. All rights reserved.
//

import UIKit
import CoreBluetooth
import Toast_Swift
import AVFoundation
import CoreLocation

extension StringProtocol where Index == String.Index {
    func index(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.lowerBound
    }
    func endIndex(of string: Self, options: String.CompareOptions = []) -> Index? {
        return range(of: string, options: options)?.upperBound
    }
    func indexes(of string: Self, options: String.CompareOptions = []) -> [Index] {
        var result: [Index] = []
        var start = startIndex
        while start < endIndex,
            let range = self[start..<endIndex].range(of: string, options: options) {
                result.append(range.lowerBound)
                start = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
    func ranges(of string: Self, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var start = startIndex
        while start < endIndex,
            let range = self[start..<endIndex].range(of: string, options: options) {
                result.append(range)
                start = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

class ViewController: UIViewController, CBCentralManagerDelegate, BeaconTrackerDelegate {

    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var statusBar: UILabel!
    
    let centralManager = CBCentralManager(delegate: nil, queue: nil, options: nil)
    var isScanning = false
    
    var timer: Timer!
    
    var prevRecord: [String: Any]?
    var prevRSSI: Int = 0
    var prevMinor: Int = 0
    var flag = false
    static let COUNT = 3
    var trigger: Int = COUNT
    
    var audioPlayer: AVAudioPlayer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.searchView.layer.shadowRadius = 4
        self.searchView.layer.shadowColor = UIColor.black.cgColor
        self.searchView.layer.shadowOffset = CGSize(width: 0, height: 4)
        centralManager.delegate = self
        updateUI()
        UserDefaults.standard.register(defaults: ["tag_id" : 0])
        
        do {
            if let fileURL = Bundle.main.path(forResource: "alarm", ofType: "mp3") {
                self.audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: fileURL))
                self.audioPlayer?.numberOfLoops = -1
//                self.audioPlayer?.play()
            } else {
                print("No file with specified name exists")
            }
        } catch let error {
            print("Can't play the audio file failed with an error \(error.localizedDescription)")
        }
        
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.applicationEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    //MARK: Application Observers
//    @objc private func applicationEnterBackground() {
//        let _ = BackgroundTaskManager.shared.beginNewBackgroundTask()
//    }

    @IBAction func onToggle(_ sender: Any) {
        let major = UserDefaults.standard.integer(forKey: "tag_id")
        print("major \(major)")
        guard major != 0 else {
            self.view.makeToast("Please scan My Tag")
            return
        }
        
        if isScanning {
            stopScanning()
        }
        else {
            startScanning()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        print("prepare for segue")
        self.stopScanning()
    }
    
    func updateUI() {
        if isScanning {
            self.toggleButton.setBackgroundImage(UIImage(named: "on"), for: .normal)
        }
        else {
            self.toggleButton.setBackgroundImage(UIImage(named: "off"), for: .normal)
        }
        
    }
    
    func startScanning() {
        if isScanning {
            return
        }
//        self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        BeaconTracker.shared.delegate = self
        BeaconTracker.shared.startBeaconTracking(ESTIMOTE_PROXIMITY_UUID, regionID: SAMPLE_REGION_ID)
        
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            var message = ""
            
            if self.prevMinor != 0 {
//                let raw = "\(self.prevRecord!)"
//                var index = raw.index(of: "1802")
//                var index1 = raw.index(index!, offsetBy: 8)
//                var index2 = raw.index(index!, offsetBy: 9)
//                var sub = raw[index1 ... index2]
//                let locked = UInt(sub, radix: 16)!
////                print(locked)
//                index = raw.index(of: "Battery")
//                index1 = raw.index(index!, offsetBy: 11)
//                index2 = raw.index(index!, offsetBy: 12)
//                sub = raw[index1 ... index2]
//                let battery = UInt(sub, radix: 16)!
//                print(battery)
//                let battery = self.prevRecord!["Battery"]
//                let locked = self.prevRecord!["1802"]
                
                let locked: Int = self.prevMinor & 0xFF
                let battery: Int = (self.prevMinor >> 8) & 0xFF
                
//                print(self.prevMinor, battery, locked)
                
                if self.prevRSSI < -80 {
                    if self.flag == true {
                        self.trigger -= 1
                    }
                }
                else {
                    if locked == 1 {
                        // stop sound
                        if self.audioPlayer != nil && self.audioPlayer!.isPlaying == true {
                            self.audioPlayer?.stop()
                        }
//                        NSLog("stop sound")
                    }
                    self.flag = true
                    self.trigger = ViewController.COUNT
                }
                
                if locked == 0 {
                    self.flag = false
                    // stop sound
                    if self.audioPlayer != nil && self.audioPlayer!.isPlaying == true {
                        self.audioPlayer?.stop()
                    }
//                    NSLog("stop sound")
                }
                
                if self.flag && (self.trigger < 0) {
                    // start sound
                    
                    if self.audioPlayer != nil && self.audioPlayer!.isPlaying == false {
                        self.audioPlayer?.play()
                    }
                    
//                    NSLog("start sound")
                    self.trigger = -1
                }
                
                message = "RSSI: \(self.prevRSSI) Battery: \(battery)% Belt: \(locked==1 ? "locked" : "unlocked")"
            }
            else {
                if self.flag == true {
                    self.trigger -= 1
                }
                message = "RSSI: N/A | Battery: N/A | Belt: N/A"
            }
            
            self.statusBar.text = message
            NSLog(message)

            self.prevMinor = 0
            self.prevRSSI = -200
        }
        
        isScanning = true
        updateUI()
    }
    
    func stopScanning() {
        if !isScanning {
            return
        }
        self.timer.invalidate()
//        self.centralManager.stopScan()
        BeaconTracker.shared.stopBeaconTracking()

        isScanning = false;
        updateUI()
    }
    
    
    
    
    func beaconTracker(_ beaconTracker: BeaconTracker, didChangeNearestBeacon nearestBeacon: CLBeacon?) {
    }
    
    func beaconTracker(_ beaconTracker: BeaconTracker, updateBeacons beacons: [CLBeacon]) {
        guard beacons.count != 0 else {
            return
        }
        
        let nearestBeacon = beacons[0]

        let major = UserDefaults.standard.integer(forKey: "tag_id")
        guard major == nearestBeacon.major.intValue else {
            return
        }
        
        self.prevMinor = nearestBeacon.minor.intValue
        self.prevRSSI = nearestBeacon.rssi == 0 ? -200 : nearestBeacon.rssi
        
    }
    
    func beaconTrackerNeedToTurnOnBluetooth(_ beaconTracker: BeaconTracker) {
        let alertController = UIAlertController(title: "Turn On Bluetooth", message: "Please turn on Bluetooth for Tag Scanning", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    

    
    
    
    
    
    
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name != "MAGTAG" || peripheral.identifier.uuidString != ShareObject.instance.deviceId {
            return
        }
        
        prevRecord = advertisementData
        prevRSSI = RSSI.intValue
        
//        NSLog("\(peripheral.name) \(advertisementData) \(RSSI.intValue)")
//
//        self.statusBar.text = "RSSI: \(RSSI.intValue) Battery: \(advertisementData["Battery"])% Belt: \(advertisementData["1802"])"

    }

}

