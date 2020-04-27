//
//  FPTriggerAlert.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 24/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPTriggerAlert: NSObject {
    
    var id: Int
    var date: Date
    var triggerAmount: Double
    var product: FPProduct
    
    init (id: Int, date: Date, triggerAmount: Double, product: FPProduct) {
        self.id = id
        self.date = date
        self.triggerAmount = triggerAmount
        self.product = product
        super.init()
    }
   
}
