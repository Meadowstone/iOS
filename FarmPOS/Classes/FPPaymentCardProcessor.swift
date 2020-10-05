//
//  FPPaymentCardProcessor.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 05/10/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPPaymentCardProcessor {
    let name: String
    let transactionFeePercentage: Double
    let transactionFeeFixed: Double
    
    init(name: String, transactionFeePercentage: Double, transactionFeeFixed: Double) {
        self.name = name
        self.transactionFeePercentage = transactionFeePercentage
        self.transactionFeeFixed = transactionFeeFixed
    }
}
