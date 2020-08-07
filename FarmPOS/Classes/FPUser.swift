//
//  FPUser.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/27/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

var _activeUser: FPUser?

enum FPLoginStatus: Int {
    case loggedIn
    case loggedOut
}

class FPBaseUser : NSObject {
    
    var id = -1
    var email = ""
    
}

class FPUser : FPBaseUser {
    
    var defaultStateCode = ""
    var farmId = ""
    var farm: FPFarm?
    
    class func storagePath() -> String {
        let documents = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] 
        let path = "\(documents)/user.dat"
        return path
    }
    
    class func save(_ user: FPUser) {
        _activeUser = user
        let info = FPModelParser.infoWithUser(user)
        NSKeyedArchiver.archiveRootObject(info, toFile: self.storagePath())
    }
    
    class func deleteActiveUser() {
        if FileManager.default.fileExists(atPath: self.storagePath()) {
            _activeUser = nil
            try! FileManager.default.removeItem(atPath: self.storagePath())
        }
    }
    
    class func activeUser() -> FPUser? {
        if _activeUser == nil && FileManager.default.fileExists(atPath: self.storagePath()) {
            let userInfo = NSKeyedUnarchiver.unarchiveObject(withFile: self.storagePath()) as! NSDictionary
            _activeUser = FPModelParser.userWithInfo(userInfo)
        }
        return _activeUser
    }
    
}
