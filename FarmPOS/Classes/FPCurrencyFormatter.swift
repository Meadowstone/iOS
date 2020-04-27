//
//  FPCurrencyFormatter.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/8/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCurrencyFormatter {
    
    class func roundCrrency(_ currency: Double) -> Double {
        let p = Double(round((currency * 10000.0)) / 10000.0) // gonna BIH
        return Double(round((p * 100.0)) / 100.0)
    }
    
    class func intCurrencyRepresentation(_ currency: Double) -> Int {
        return Int(currency * 100.0)
    }
    
    class func printableCurrency(_ currency: Double) -> String {
        return String(format: "%.2f", currency)
    }
    
}
