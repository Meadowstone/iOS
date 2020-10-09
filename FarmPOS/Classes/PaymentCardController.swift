//
//  PaymentCardController.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 08/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import Stripe

class PaymentCardController: NSObject {
    
    enum PaymentResult {
        case success
        case canceled
        case error(message: String?)
    }
    
    static let shared = PaymentCardController()
    var paymentProcessor: FPPaymentCardProcessor?
    private var paymentIntentClientSecret: String?
    
    func initialize() {
        #if Devbuild
        Stripe.setDefaultPublishableKey("pk_test_K3By3BKoIS1Um4kOqX2VnTIC")
        #else
        Stripe.setDefaultPublishableKey("pk_live_kiMVjsyb2V1IyM9br7Ylnj5b")
        #endif
    }
    
    func priceWithAddedFees(forPrice price: Double) -> Double {
        guard let paymentProcessor = paymentProcessor else { return price }
        return FPCurrencyFormatter.roundCrrency(
            (price + paymentProcessor.transactionFeeFixed)
            / (1 - paymentProcessor.transactionFeePercentage / 100)       
        )
    }
    
    func createPaymentIntent(forPrice price: Double, email: String?, completion: @escaping ((_ didSucceed: Bool) -> Void)) {
        FPServer.sharedInstance.createStripePaymentIntent(forAmount: price * 100, email: email) { [weak self] clientSecret in
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
        completion: @escaping ((PaymentResult) -> Void)
    ) {
        guard let paymentIntentClientSecret = paymentIntentClientSecret else { return }
        
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPPaymentHandler.shared().confirmPayment(withParams: paymentIntentParams, authenticationContext: context) { status, paymentIntent, error in
            switch status {
            case .canceled:
                completion(.canceled)
            case .failed:
                completion(.error(message: error?.localizedDescription))
            case .succeeded:
                completion(.success)
            @unknown default:
                break
            }
        }
    }
    
}
