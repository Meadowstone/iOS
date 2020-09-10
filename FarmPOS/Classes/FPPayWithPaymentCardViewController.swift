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
    
    var paymentSucceeded: (() -> Void)?
    var unableToStartPayment: (() -> Void)?
    
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
        payButton.backgroundColor = .blue
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        stackView.addArrangedSubview(payButton)
        
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.backgroundColor = .red
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        stackView.addArrangedSubview(cancelButton) 
    }
    
    override func viewDidLoad() {
        createPaymentIntent()
    }
    
    private func createPaymentIntent() {
        // STRIPE TODO: call from here or extract somewhere else?
        let checkoutSum = FPCartView.sharedCart().checkoutSum
        FPServer.sharedInstance.createStripePaymentIntent(forAmount: checkoutSum) { [weak self] clientSecret in
            guard let clientSecret = clientSecret else {
                self?.unableToStartPayment?()
                return
            }
            self?.paymentIntentClientSecret = clientSecret
        }
    }
    
    @objc func payTapped() {
        guard let paymentIntentClientSecret = paymentIntentClientSecret else { return /* STRIPE TODO: decide what to do here */ }
        
        // STRIPE TODO: should this be done here or somewhere else?
        let paymentMethodParams = STPPaymentMethodParams(card: paymentCardDetailsField.cardParams, billingDetails: nil, metadata: nil)
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        paymentIntentParams.paymentMethodParams = paymentMethodParams
        
        STPPaymentHandler.shared().confirmPayment(withParams: paymentIntentParams, authenticationContext: self) { [weak self] status, paymentIntent, error in
            // STRIPE TODO: check if this status handling is ok
            switch status {
            case .failed:
                FPAlertManager.showMessage(error?.localizedDescription ?? "", withTitle: "Payment failed")
            case .canceled:
                FPAlertManager.showMessage(error?.localizedDescription ?? "", withTitle: "Payment canceled")
            case .succeeded:
                //STRIPE TODO: remove this?
                //FPAlertManager.showMessage(paymentIntent?.description ?? "", withTitle: "Payment succeeded")
                self?.paymentSucceeded?()
            @unknown default:
                // STRIPE TODO: decide what to do here
                break
            }
        }
    }
    
    @objc func cancelTapped() {
        presentingViewController?.dismiss(animated: true)
    }

}

extension FPPayWithPaymentCardViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}
