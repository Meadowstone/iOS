//
//  FPCustomer.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/3/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

var _activeCustomer: FPCustomer?
class FPCustomer : NSObject {
    
    var id = -1
    var email = ""
    var phone = ""
    var name = ""
    var pin = ""
    var balance: Double = 0.0
    var farmBucks: Double = 0.0
    var phoneHome: String?
    var address: String?
    var city: String?
    var state: String?
    var wholesale: Bool = false
    var hasOverdueBalance: Bool = false
    var overduePopoverShown: Bool = false
    var synchronized: Bool = true // indicates that the customer was created and synchronized with the server or created outside of the application. Used to fetch and re-synchronize all customers that were created without active internet connection.
    var zip: String?
    var voidTransactionProducts: [NSDictionary]?
    var productDescriptors = [FPProductDescriptor]()
    override var description: String {
        return "Customer: \(name), email: \(email), pin: \(pin), id: \(id)\n"
    }
    
    class func setActiveCustomer(_ customer: FPCustomer?) {
        FPProduct.reloadAllProducts()
        _activeCustomer = customer
        
        if let customer = customer {
            FPProduct.addDiscounts(using: customer.productDescriptors)
        }
    }
    
    class func activeCustomer() -> FPCustomer? {
        return _activeCustomer
    }
        
}
