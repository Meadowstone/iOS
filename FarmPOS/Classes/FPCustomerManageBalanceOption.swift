//
//  FPCustomerManageBalanceOption.swift
//  Farm POS
//
//  Created by Denis Mendica on 07/10/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCustomerManageBalanceOption {
    
    static var currentOptions = [FPCustomerManageBalanceOption]()
    
    let price: Double
    let balanceAdded: Double
    
    init(price: Double, balanceAdded: Double) {
        self.price = price
        self.balanceAdded = balanceAdded
    }
    
}
