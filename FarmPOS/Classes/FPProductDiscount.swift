//
//  FPProductDiscount.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 01/09/2014.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPProductDiscount: NSObject {
    
    var day: Int
    var productId: Int
    var discount: Double
    
    init(day: Int, productId: Int, discount: Double) {
        self.day = day
        self.productId = productId
        self.discount = discount
        super.init()
    }
   
}
