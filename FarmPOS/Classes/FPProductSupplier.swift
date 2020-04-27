//
//  FPProductSupplier.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 22/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPProductSupplier: NSObject, FPNamable {
   
    var id: Int
    var name: String {
        if let c = companyName {
            return c
        } else if let c = contactName {
            return c
        } else {
            return ""
        }
    }
    var companyName: String?
    var contactName: String?
    
    init(id: Int, companyName: String?, contactName: String?) {
        self.id = id
        self.companyName = companyName
        self.contactName = contactName
        super.init()
    }
    
}
