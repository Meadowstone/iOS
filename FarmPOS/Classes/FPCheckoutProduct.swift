//
//  FPCheckoutProduct.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/18/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCheckoutProduct: FPCheckoutItem {
    
    var product: FPProduct
    var quantity: Double
    var isCSA: Bool
    
    init(product: FPProduct, quantity: Double, sum: Double, isCSA: Bool) {
        self.product = product
        self.quantity = quantity
        self.isCSA = isCSA
        super.init(sum: sum)
    }
    
}
