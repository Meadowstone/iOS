//
//  FPTransaction.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/17/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

var _activeTransaction: FPTransaction?

class FPTransaction : NSObject {
    
    enum PaymentType : Int {
        case card = 1
        case cash = 2
        case check = 3
        case payLater = 4
        case credits = 5
        case unknown = 6
        
        func toString() -> String {
            var text = ""
            switch self {
                case .card:
                    text = "Credit Card"
                case .cash:
                    text = "Cash"
                case .check:
                    text = "Check"
                case .payLater:
                    text = "Pay Later"
                case .credits:
                    text = "Balance"
                case .unknown:
                    text = "Unknown"
            }
            return text
        }
    }
    
    var id = -1
    var paymentDate: Date!
    var sum = 0.0
    var voided = false
    var isOrdered = false
    var last4: String?
    var customer: FPCustomer!
    var paymentType = PaymentType.card
    var retailLocation: FPRetailLocation!
    
    class func setActiveTransaction(_ t: FPTransaction?) {
        _activeTransaction = t
        if _activeTransaction != nil {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPTransactionOrOrderProcessingNotification), object: nil)
        }
    }
    
    class func activeTransaction() -> FPTransaction? {
        return _activeTransaction
    }
}
