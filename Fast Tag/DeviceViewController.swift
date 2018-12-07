//
//  DeviceViewController.swift
//  Fast Tag
//
//  Created by Guru on 12/6/18.
//  Copyright © 2018 Guru. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceViewController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var toogle: UIButton!
    @IBOutlet weak var table: UITableView!
    
    let centralManager = CBCentralManager(delegate: nil, queue: nil, options: nil)
    
    var isScanning = false;
    var devices: [CBPeripheral]! = []

    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager.delegate = self
        // Do any additional setup after loading the view.
        updateUI()
    }
    
    @IBAction func onBack(_ sender: Any) {
        stopScanning()
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
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        NSLog("\(peripheral.name) \(advertisementData) \(RSSI.intValue)")
        
        if peripheral.name != "MAGTAG" {
            return
        }
        devices.append(peripheral)
        print(devices)
        self.table.reloadData()
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = "\(device.identifier.uuidString)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let device = devices[indexPath.row]
        ShareObject.instance.deviceId = device.identifier.uuidString
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
