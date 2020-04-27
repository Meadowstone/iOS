//
//  FPMeasurement.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

var _allMeasurements: Array<FPMeasurement>?
class FPMeasurement : NSObject, FPNamable {
    
    var id: Int
    var shortName: String
    var longName: String
    var name: String {
        return self.shortName + " - " + self.longName
    }
    
    init(id: Int, shortName: String, longName: String) {
        self.id = id
        self.shortName = shortName
        self.longName = longName
        super.init()
    }
    
    class func storagePath() -> String {
        let documents = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] 
        let path = "\(documents)/measurements.dat"
        return path
    }
    
    class func allMeasurements() -> Array<FPMeasurement>? {
        if _allMeasurements == nil && FileManager.default.fileExists(atPath: self.storagePath()) {
            let measurementsInfo = NSKeyedUnarchiver.unarchiveObject(withFile: self.storagePath()) as! [NSDictionary]
            var measurements = [FPMeasurement]()
            for info in measurementsInfo {
                measurements.append(FPModelParser.measurementWithInfo(info))
            }
            _allMeasurements = measurements
        }
        return _allMeasurements
    }
    
    class func setAllMeasurements(_ allMeasurements: Array<FPMeasurement>?) {
        _allMeasurements = allMeasurements
        
        if let am = _allMeasurements {
            var storeInfo = [NSDictionary]()
            for m in am {
                storeInfo.append(FPModelParser.infoWithMeasurement(m))
            }
            NSKeyedArchiver.archiveRootObject(storeInfo, toFile: self.storagePath())
        } else {
            if FileManager.default.fileExists(atPath: self.storagePath()) {
                try! FileManager.default.removeItem(atPath: self.storagePath())
            }
        }
    }
}
