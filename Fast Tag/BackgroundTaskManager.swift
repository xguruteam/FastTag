//
//  BackgroundTaskManager.swift
//  Fast Tag
//
//  Created by Guru on 12/9/18.
//  Copyright © 2018 Guru. All rights reserved.
//

import UIKit
import os.log

//MARK: Log functions
class Log {
    static func e(_ message: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", log: OSLog.default, type: .error, message)
        } else {
            print("CoreiBeacon Error: \(message)")
        }
    }
    
    static func d(_ message: String) {
        self.e(message)
    }
}


//MARK: BackgroundTaskManager
class BackgroundTaskManager: NSObject {
    
    static let shared = BackgroundTaskManager()
    
    var bgTaskIdList: [UIBackgroundTaskIdentifier] = []
    var masterTaskId: UIBackgroundTaskIdentifier = .invalid
    
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        
        let application = UIApplication.shared
        var bgTaskId: UIBackgroundTaskIdentifier = .invalid
        
        if application.responds(to: #selector(UIApplication.beginBackgroundTask(withName:expirationHandler:))) {
            bgTaskId = application.beginBackgroundTask(expirationHandler: {
                [weak self] in
                Log.d("background task \(bgTaskId) expired")
                guard let index = self?.bgTaskIdList.index(of: bgTaskId) else {
                    Log.e("Invaild Task \(bgTaskId)")
                    return
                }
                application.endBackgroundTask(bgTaskId)
                self?.bgTaskIdList.remove(at: index)
            })
            
            if self.masterTaskId == .invalid {
                self.masterTaskId = bgTaskId
                Log.d("start master task \(bgTaskId)")
            }
            else {
                Log.d("started background task \(bgTaskId)")
                self.bgTaskIdList.append(bgTaskId)
                self.endBackgroundTasks()
            }
        }
        return bgTaskId
    }
    
    func endBackgroundTasks() {
        self.drainBGTaskList(all: false)
    }
    
    func endAllBackgroundTasks() {
        self.drainBGTaskList(all: true)
    }
    
    func drainBGTaskList(all: Bool) {
        let application = UIApplication.shared
        if application.responds(to: #selector(UIApplication.endBackgroundTask(_:))) {
            let count = self.bgTaskIdList.count
            for _ in (all ? 0 : 1) ..< count {
                let bgTaskId = self.bgTaskIdList[0]
                Log.d("ending background task with id\(bgTaskId)")
                application.endBackgroundTask(bgTaskId)
                self.bgTaskIdList.remove(at: 0)
            }
            
            if self.bgTaskIdList.count > 0 {
                Log.d("kept background task id \(self.bgTaskIdList[0])")
            }
            
            if all {
                Log.d("no more background tasks running")
                application.endBackgroundTask(self.masterTaskId)
                self.masterTaskId = .invalid
            }
            else {
                Log.d("kept master background task id \(self.masterTaskId)")
            }
        }
    }
}
