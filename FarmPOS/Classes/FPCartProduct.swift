//
//  FPCartProduct.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/8/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCartProduct : NSObject {
    
    var product: FPProduct
    var notes = ""
    var csaCreditsUsed: Int = 0
    var quantityCSA: Double = 0.0
    var quantityPaid: Double = 0.0
    var quantity: Double = 0.0
    var sum: Double! {
        return FPCurrencyFormatter.roundCrrency(quantityPaid * product.actualPrice)
    }
    var sumWithTax: Double! {
        return FPCurrencyFormatter.roundCrrency(quantityPaid * product.actualPriceWithTax)
    }
//    var taxSum: Double! {
//        return FPCurrencyFormatter.roundCrrency(quantityPaid * product.pureTaxValue)
//    }
    var taxSumRaw: Double! {
        var taxSumRaw = 0.0
        if let tax = self.product.category.tax {
            taxSumRaw = FPCurrencyFormatter.roundCrrency(quantityPaid * ((self.product.actualPrice / 100.0) * tax.rate))
        }
        return taxSumRaw
    }
    
    init (product: FPProduct) {
        self.product = product
        if  product.measurement.longName.lowercased().range(of: "pound", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) == nil {
            self.quantity = 1.0
        }
        super.init()
    }
    
}
