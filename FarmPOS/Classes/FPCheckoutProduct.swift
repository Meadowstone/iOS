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
    
    init(product: FPProduct, quantity: Double, sum: Double) {
        self.product = product
        self.quantity = quantity
        super.init(sum: sum)
    }
    
}
