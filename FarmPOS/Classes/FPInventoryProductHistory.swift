//
//  FPInventoryProductHistory.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 30/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPInventoryProductHistory: NSObject {
    
    var id: Int
    var dateCreated: Date
    var amount: Double
    
    init (id: Int, dateCreated: Date, amount: Double) {
        self.id = id
        self.dateCreated = dateCreated
        self.amount = amount
        super.init()
    }
    
}
