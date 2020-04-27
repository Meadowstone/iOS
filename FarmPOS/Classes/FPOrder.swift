//
//  FPOrder.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/16/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

var _activeOrder: FPOrder?

class FPOrder : NSObject {
    
    enum ShippingOption : Int {
        case toDoor = 1
        case farmstand = 2
        case dropSite = 3
        case electronicDelivery = 4
        case notSelected = 5
        
        func toString() -> String {
            var text = ""
            switch self {
                case .toDoor:
                    text = "To door"
                case .farmstand:
                    text = "Farmstand"
                case .dropSite:
                    text = "Drop site"
                case .electronicDelivery:
                    text = "Electronic delivery"
                case .notSelected:
                    text = "Not selected"
            }
            return text
        }
    }
    
    var id = -1
    var shippingOption = ShippingOption.toDoor
    var isPaid = false
    var address = ""
    var city = ""
    var state = ""
    var zipCode = ""
    var customer: FPCustomer!
    var dueDate: Date!
    var cartProductsInfo: [NSDictionary]!
    
    class func activeOrder() -> FPOrder? {
        return _activeOrder
    }
    
    class func setActiveOrder(_ order: FPOrder?) {
        _activeOrder = order
        
        var title = "Check Out"
        if _activeOrder != nil {
            title = "Fulfill"
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPTransactionOrOrderProcessingNotification), object: nil)
        }
        FPCartView.sharedCart().headerView.checkoutBtn.setTitle(title, for: .normal)
    }
    
}
