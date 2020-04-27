//
//  FPCheckoutItem.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 15/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCheckoutItem: NSObject {
    
    var sum: Double
    
    init (sum: Double) {
        self.sum = sum
        super.init()
    }
    
}
