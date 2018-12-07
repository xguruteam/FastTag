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

class ViewController: UIViewController, CBCentralManagerDelegate {

    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var toggleButton: UIButton!
    @IBOutlet weak var statusBar: UILabel!
    
    let centralManager = CBCentralManager(delegate: nil, queue: nil, options: nil)
    var isScanning = false
    
    var timer: Timer!
    
    var prevRecord: [String: Any]?
    var prevRSSI: Int = 0
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
    }

    @IBAction func onToggle(_ sender: Any) {
        guard ShareObject.instance.deviceId != nil else {
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
        self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            var message = ""
            
            if let _ = self.prevRecord {
                let raw = "\(self.prevRecord!)"
                var index = raw.index(of: "1802")
                var index1 = raw.index(index!, offsetBy: 8)
                var index2 = raw.index(index!, offsetBy: 9)
                var sub = raw[index1 ... index2]
                let locked = UInt(sub, radix: 16)!
//                print(locked)
                index = raw.index(of: "Battery")
                index1 = raw.index(index!, offsetBy: 11)
                index2 = raw.index(index!, offsetBy: 12)
                sub = raw[index1 ... index2]
                let battery = UInt(sub, radix: 16)!
//                print(battery)
//                let battery = self.prevRecord!["Battery"]
//                let locked = self.prevRecord!["1802"]
                
                if self.prevRSSI < -70 {
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
                        NSLog("stop sound")
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
                    NSLog("stop sound")
                }
                
                if self.flag && (self.trigger < 0) {
                    // start sound
                    
                    if self.audioPlayer != nil && self.audioPlayer!.isPlaying == false {
                        self.audioPlayer?.play()
                    }
                    
                    NSLog("start sound")
                    self.trigger = -1
                }
                
                message = "RSSI: \(self.prevRSSI) Battery: \(battery)% Belt: \(locked)"
            }
            else {
                if self.flag == true {
                    self.trigger -= 1
                }
                message = "RSSI: N/A | Battery: N/A | Belt: N/A"
            }
            
            self.statusBar.text = message
        }
        
        isScanning = true
        updateUI()
    }
    
    func stopScanning() {
        if !isScanning {
            return
        }
        self.centralManager.stopScan()
        self.timer.invalidate()
        
        isScanning = false;
        updateUI()
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

