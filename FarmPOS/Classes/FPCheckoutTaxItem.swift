//
//  FPCheckoutTaxItem.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 15/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCheckoutTaxItem: FPCheckoutItem {
    
    var tax: FPProductCategoryTax
    
    init(tax: FPProductCategoryTax, sum: Double) {
        self.tax = tax
        super.init(sum: sum)
    }
    
}
