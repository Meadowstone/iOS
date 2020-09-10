//
//  CreditCardProcessor.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 08/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import UIKit // STRIPE TODO: ok to use UIKit in this layer?
import Stripe

// STRIPE TODO: rename to PaymentCardProcessor?
class CreditCardProcessor: NSObject {
    
    static let shared = CreditCardProcessor()
    private var customerContext: STPCustomerContext?
    private var paymentContext: STPPaymentContext?
    
    func initialize() {
        #if Devbuild
        Stripe.setDefaultPublishableKey("pk_test_K3By3BKoIS1Um4kOqX2VnTIC")
        #else
        Stripe.setDefaultPublishableKey("pk_live_kiMVjsyb2V1IyM9br7Ylnj5b")
        #endif
    }
    
    func customerDidLogIn() {
        //customerContext = STPCustomerContext(keyProvider: FPServer.shared) // STRIPE TODO: save credit cards? then use this.
    }
    
    // STRIPE TODO: ok to pass UIKit class into this layer? 
    func customerDidTapPayWithCreditCard(from viewController: UIViewController) {
        guard let customerContext = customerContext else { return }
        paymentContext = STPPaymentContext(customerContext: customerContext)
        paymentContext?.delegate = self
        paymentContext?.hostViewController = viewController
        // STRIPE TODO: use Apple Pay? then also set paymentAmount.
        paymentContext?.presentPaymentOptionsViewController() // STRIPE TODO: ok to directly modify UI from this layer?
    }
    
}

extension CreditCardProcessor: STPPaymentContextDelegate {
    
    // STRIPE TODO: figure out what to do here
    func paymentContextDidChange(_ paymentContext: STPPaymentContext) {
        
    }
    
    // STRIPE TODO: figure out what to do here
    func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error) {
        
    }
    
    // STRIPE TODO: figure out what to do here
    func paymentContext(_ paymentContext: STPPaymentContext, didCreatePaymentResult paymentResult: STPPaymentResult, completion: @escaping STPPaymentStatusBlock) {
        
    }
    
    // STRIPE TODO: figure out what to do here
    func paymentContext(_ paymentContext: STPPaymentContext, didFinishWith status: STPPaymentStatus, error: Error?) {
        
    }
    
}
