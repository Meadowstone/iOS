//
//  FPPaymentCardDetailsViewController.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 10/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import UIKit
import Stripe

class FPPayWithPaymentCardViewController: UIViewController {
    
    private var stackView: UIStackView!
    private var paymentCardDetailsField: STPPaymentCardTextField!
    private var payButton: UIButton!
    
    private var paymentIntentClientSecret: String? // STRIPE TODO: should this be here or somewhere else?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = .white
        
        stackView = UIStackView()
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        paymentCardDetailsField = STPPaymentCardTextField()
        // STRIPE TODO: remove ZIP field?
        stackView.addArrangedSubview(paymentCardDetailsField)
        
        payButton = UIButton()
        payButton.setTitle("Pay", for: .normal)
        payButton.backgroundColor = .green
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        stackView.addArrangedSubview(payButton)
    }
    
    override func viewDidLoad() {
        createPaymentIntent()
    }
    
    private func createPaymentIntent() {
        // STRIPE TODO: call from here or extract somewhere else?
        FPServer.sharedInstance.createStripePaymentIntent { [weak self] error, clientSecret in
        // STRIPE TODO: handle error
            self?.paymentIntentClientSecret = clientSecret
        }
    }
    
    @objc func payTapped() {
        guard let paymentIntentClientSecret = paymentIntentClientSecret else { return /* STRIPE TODO: decide what to do here */ }
        
        // STRIPE TODO: should this be done here or somewhere else?
        let paymentMethodParams = STPPaymentMethodParams(card: paymentCardDetailsField.cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPPaymentHandler.shared().confirmPayment(withParams: paymentIntentParams, authenticationContext: self) { status, paymentIntent, error in
            // STRIPE TODO: check if this status handling is ok
            switch status {
            case .failed:
                FPAlertManager.showMessage(error?.localizedDescription ?? "", withTitle: "Payment failed")
            case .canceled:
                FPAlertManager.showMessage(error?.localizedDescription ?? "", withTitle: "Payment canceled")
            case .succeeded:
                FPAlertManager.showMessage(paymentIntent?.description ?? "", withTitle: "Payment succeeded")
            @unknown default:
                // STRIPE TODO: decide what to do here
                break
            }
        }
    } 

}

extension FPPayWithPaymentCardViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}