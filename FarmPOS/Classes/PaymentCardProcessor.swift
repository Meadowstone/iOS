//
//  PaymentCardProcessor.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 08/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import Stripe

class PaymentCardProcessor: NSObject {
    
    enum PaymentResult {
        case success
        case canceled
        case error(message: String?)
    }
    
    static let shared = PaymentCardProcessor()
    private var paymentIntentClientSecret: String?
    
    func initialize() {
        #if Devbuild
        Stripe.setDefaultPublishableKey("pk_test_K3By3BKoIS1Um4kOqX2VnTIC")
        #else
        Stripe.setDefaultPublishableKey("pk_live_kiMVjsyb2V1IyM9br7Ylnj5b")
        #endif
    }
    
    func createPaymentIntent(completion: @escaping ((_ didSucceed: Bool) -> Void)) {
        let checkoutSum = FPCartView.sharedCart().checkoutSum
        FPServer.sharedInstance.createStripePaymentIntent(forAmount: checkoutSum * 100) { [weak self] clientSecret in
            guard let clientSecret = clientSecret else {
                completion(false)
                return
            }
            self?.paymentIntentClientSecret = clientSecret
            completion(true)
        }
    }
    
    func performPayment(
        with cardParams: STPPaymentMethodCardParams,
        in context: STPAuthenticationContext,
        completion: @escaping ((PaymentResult) -> Void))
    {
        guard let paymentIntentClientSecret = paymentIntentClientSecret else { return }
        
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPPaymentHandler.shared().confirmPayment(withParams: paymentIntentParams, authenticationContext: context) { status, paymentIntent, error in
            switch status {
            case .failed:
                completion(.error(message: error?.localizedDescription))
            case .canceled:
                completion(.canceled)
            case .succeeded:
                completion(.success)
            @unknown default:
                break
            }
        }
    }
    
}