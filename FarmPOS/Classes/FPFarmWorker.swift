//
//  FPFarmWorker.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/30/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

var _activeWorker: FPFarmWorker?
var _allWorkers: [FPFarmWorker]?

class FPFarmWorker : FPBaseUser {
    
    class func setActiveWorker(_ activeWorker: FPFarmWorker?) {
        _activeWorker = activeWorker
    }
    
    class func activeWorker() -> FPFarmWorker? {
        return _activeWorker
    }
    
    class func storagePath() -> String {
        let documents = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let path = "\(documents)/workers.dat"
        return path
    }
    
    class func allWorkers() -> [FPFarmWorker]? {
        if _allWorkers == nil && FileManager.default.fileExists(atPath: self.storagePath()) {
            let storedInfo = NSKeyedUnarchiver.unarchiveObject(withFile: self.storagePath()) as! [NSDictionary]
            var newInfo = [FPFarmWorker]()
            for info in storedInfo {
                newInfo.append(FPModelParser.workerWithInfo(info))
            }
            _allWorkers = newInfo
        }
        return _allWorkers
    }
    
    class func setAllWorkers(_ workers: Array<FPFarmWorker>?) {
        _allWorkers = workers
        
        if let allItems = _allWorkers {
            var storeInfo = [NSDictionary]()
            for item in allItems {
                storeInfo.append(FPModelParser.infoWithFarmWorker(item))
            }
            NSKeyedArchiver.archiveRootObject(storeInfo, toFile: self.storagePath())
        } else {
            if FileManager.default.fileExists(atPath: self.storagePath()) {
                try! FileManager.default.removeItem(atPath: self.storagePath())
            }
        }
    }
    
}
