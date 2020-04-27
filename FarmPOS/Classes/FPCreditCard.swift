//
//  FPCreditCard.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCreditCard: NSObject {
    
    var cvv: String?
    var cardNumber: String?
    var expirationDateString: String?
    
    var isDefault: Bool = false
    var label = ""
    var last4 = ""
    var token = ""
    // Printable
    override var description: String {
        return "Last 4: \(last4), token: \(token), default: \(isDefault)"
    }
    
    override init() {
        super.init()
    }
    
    init(isDefault: Bool, label: String, last4: String, token: String) {
        self.isDefault = isDefault
        self.label = label
        self.last4 = last4
        self.token = token
        super.init()
    }
}
