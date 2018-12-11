//
//  DeviceViewController.swift
//  Fast Tag
//
//  Created by Guru on 12/6/18.
//  Copyright © 2018 Guru. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class DeviceViewController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource, BeaconTrackerDelegate {
    
    @IBOutlet weak var toogle: UIButton!
    @IBOutlet weak var table: UITableView!
    
    let centralManager = CBCentralManager(delegate: nil, queue: nil, options: nil)
    
    var isScanning = false;
    var devices: [CLBeacon]! = []

    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager.delegate = self
        // Do any additional setup after loading the view.
        updateUI()
        
        BeaconTracker.shared.delegate = self
        BeaconTracker.shared.startBeaconTracking(ESTIMOTE_PROXIMITY_UUID, regionID: SAMPLE_REGION_ID)
    }
    
    @IBAction func onBack(_ sender: Any) {
        BeaconTracker.shared.stopBeaconTracking()
//        stopScanning()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onStartStop(_ sender: Any) {
        
        if isScanning {
            stopScanning()
        }
        else {
            startScanning()
        }
    }
    
    func updateUI() {
        if isScanning {
            self.toogle.setTitle("Stop", for: .normal)
        }
        else {
            self.toogle.setTitle("Start", for: .normal)
        }
    }
    
    func startScanning() {
        if isScanning {
            return
        }
        self.devices = []
        self.centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        isScanning = true
        updateUI()
    }
    
    func stopScanning() {
        if !isScanning {
            return
        }
        self.centralManager.stopScan()
        isScanning = false;
        updateUI()
    }
    
    func beaconTracker(_ beaconTracker: BeaconTracker, didChangeNearestBeacon nearestBeacon: CLBeacon?) {
        if let _ = nearestBeacon {
            Log.e(nearestBeacon!.keyString)
        }
        else {
            Log.e("no beacon")
        }
    }
    
    func beaconTrackerNeedToTurnOnBluetooth(_ beaconTracker: BeaconTracker) {
        let alertController = UIAlertController(title: "Turn On Bluetooth", message: "Please turn on Bluetooth for Tag Scanning", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            self.onBack(self.toogle)
        }
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }

    func beaconTracker(_ beaconTracker: BeaconTracker, updateBeacons beacons: [CLBeacon]) {
        self.devices = beacons
        self.table.reloadData()
    }

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        NSLog("\(peripheral.name) \(advertisementData) \(RSSI.intValue)")
        
        if peripheral.name != "MAGTAG" {
            return
        }
//        devices.append(peripheral)
//        print(devices)
//        self.table.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let device = devices[indexPath.row]
        cell.textLabel?.text = "Baby Tag"
        cell.detailTextLabel?.text = "\(device.major.intValue)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
//        ShareObject.instance.deviceId = device.identifier.uuidString
        UserDefaults.standard.set(device.major.intValue, forKey: "tag_id")
        onBack(self.toogle)
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
