//
//  PaymentCardController.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 08/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import Stripe
import StripeTerminal

class PaymentCardController: NSObject {
    
    let terminal = PaymentCardTerminalController()
    
    enum PaymentResult {
        case success
        case canceled
        case error(message: String?)
    }
    
    static let shared = PaymentCardController()
    private var paymentIntentClientSecret: String?
    
    func initialize() {
        #if Devbuild
        Stripe.setDefaultPublishableKey("pk_test_K3By3BKoIS1Um4kOqX2VnTIC")
        #else
        Stripe.setDefaultPublishableKey("pk_live_kiMVjsyb2V1IyM9br7Ylnj5b")
        #endif
        
        Terminal.setTokenProvider(self)
    }
    
    func priceWithAddedFees(forPrice price: Double) -> Double {
        let paymentCardProcessor = FPUser.activeUser()!.farm!.paymentCardProcessor!
        return FPCurrencyFormatter.roundCrrency(
            (price + paymentCardProcessor.transactionFeeFixed)
            / (1 - paymentCardProcessor.transactionFeePercentage / 100)       
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

extension PaymentCardController: ConnectionTokenProvider {
    
    func fetchConnectionToken(
        _ completion: @escaping ConnectionTokenCompletionBlock
    ) {
        FPServer.sharedInstance.fetchStripeConnectionToken { token in
            if let token = token {
                completion(token, nil)
            } else {
                completion(
                    nil,
                    NSError(
                        domain: "com.stripe-terminal-ios.example",
                        code: 2000,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Missing 'secret' in ConnectionToken JSON response"
                        ]
                    )
                )
            }
        }
    }
    
    func capturePaymentIntent(
        _ intent: String,
        completion: @escaping ErrorCompletionBlock
    ) {
        FPServer.sharedInstance.captureStripePaymentIntent(
            intent
        ) { success in
            if success {
                completion(nil)
            } else {
                completion(
                    NSError(
                        domain: "com.stripe-terminal-ios.example",
                        code: 0,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Networking error encountered."
                        ]
                    )
                )
            }
        }
    }
    
}

class PaymentCardTerminalController {
    
    var connectedReader: Reader? {
        return Terminal.shared.connectedReader
    }
    
    var isReaderConnected: Bool {
        return connectedReader != nil
    }
    
    @discardableResult
    func discoverReaders(
        delegate: DiscoveryDelegate,
        completion: @escaping ErrorCompletionBlock
    ) -> Cancelable? {
        Terminal.shared.discoverReaders(
            .init(
                discoveryMethod: .bluetoothScan,
                simulated: {
                    #if Devbuild
                    true
                    #else
                    false
                    #endif
                }()
            ),
            delegate: delegate,
            completion: completion
        )
    }
    
    func disconnectReader(
        _ completion: @escaping ErrorCompletionBlock
    ) {
        Terminal.shared.disconnectReader(completion)
    }
    
    func collectPayment(
        price: Double,
        email: String?,
        completion: @escaping (Result<PaymentIntent, Error>) -> ()
    ) {
        let params = PaymentIntentParameters(
            amount: UInt(price * 100),
            currency: "usd",
            paymentMethodTypes: ["card_present"]
        )
        params.receiptEmail = email
        
        Terminal.shared.createPaymentIntent(params) { result, error in
            guard let result = result
            else {
                return completion(
                    .failure(
                        error ?? NSError()
                    )
                )
            }
            
            Terminal.shared.collectPaymentMethod(result) { result, error in
                if let error = error {
                    completion(
                        .failure(error)
                    )
                } else if let result = result {
                    completion(
                        .success(result)
                    )
                }
            }
        }
    }
    
    func processPayment(
        _ paymentIntent: PaymentIntent,
        completion: @escaping (Result<String, Error>) -> ()
    ) {
        Terminal.shared.processPayment(paymentIntent) { result, error in
            if let error = error {
                completion(
                    .failure(error)
                )
            } else if let result = result {
                completion(
                    .success(result.stripeId)
                )
            }
        }
    }
    
}

// TODO: 1. Add button Pay with Terminal
// TODO: 2. If not connected, show connect button
// TODO: 2. If connected, show connect to a new terminal button
// TODO: 3. Handle connection, and process payment
// TODO: 4. Handle updates
