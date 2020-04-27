//
//  FPRetailLocation.swift
//  Farm POS
//
//  Created by Anton - MacMini on 8/6/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

let kFPDefaultRetailLocationKey = "kFPDefaultRetailLocationKey"

var _allRetailLocations: [FPRetailLocation]?
class FPRetailLocation : NSObject {
    
    var id = -1
    var name = ""
    
    override init() { super.init() }
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        super.init()
    }
    
    class func makeDefault(_ name: String) {
        UserDefaults.standard.set(name, forKey: kFPDefaultRetailLocationKey)
        UserDefaults.standard.synchronize()
    }
    
    class func removeDefault() {
        UserDefaults.standard.removeObject(forKey: kFPDefaultRetailLocationKey)
        UserDefaults.standard.synchronize()
    }
    
    class func defaultLocation() -> FPRetailLocation? {
        if let defaultLocationName = UserDefaults.standard.object(forKey: kFPDefaultRetailLocationKey) as? String {
            if let allLocations = FPRetailLocation.allRetailLocations() {
                return allLocations.filter({ (enumLocation) -> Bool in
                    return enumLocation.name == defaultLocationName
                }).first
            }
        }
        return nil
    }
    
    class func defaultLocationName() -> String? {
        return UserDefaults.standard.object(forKey: kFPDefaultRetailLocationKey) as? String
    }
    
    class func allRetailLocationsNames() -> [String]? {
        var retailLocations: [String]?
        if let arl = self.allRetailLocations()  {
            var retLocs = [String]()
            for rl in arl {
                retLocs.append(rl.name)
            }
            retailLocations = retLocs
        }
        return retailLocations
    }
    
    class func storagePath() -> String {
        let documents = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] 
        let path = "\(documents)/retail_locations.dat"
        return path
    }
    
    class func allRetailLocations() -> [FPRetailLocation]? {
        if _allRetailLocations == nil && FileManager.default.fileExists(atPath: self.storagePath()) {
            let retailLocationsInfo = NSKeyedUnarchiver.unarchiveObject(withFile: self.storagePath()) as! [NSDictionary]
            var retailLocations = [FPRetailLocation]()
            for info in retailLocationsInfo {
                retailLocations.append(FPModelParser.retailLocationWithInfo(info))
            }
            _allRetailLocations = retailLocations
        }
        return _allRetailLocations
    }
    
    class func setAllRetailLocations(_ allRetailLocations: Array<FPRetailLocation>?) {
        _allRetailLocations = allRetailLocations
        
        if let arl = _allRetailLocations {
            var storeInfo = [NSDictionary]()
            for rl in arl {
                storeInfo.append(FPModelParser.infoWithRetailLocation(rl))
            }
            NSKeyedArchiver.archiveRootObject(storeInfo, toFile: self.storagePath())
        } else {
            if FileManager.default.fileExists(atPath: self.storagePath()) {
                try! FileManager.default.removeItem(atPath: self.storagePath())
            }
        }
    }
}
