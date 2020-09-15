//
//  FPPayWithPaymentCardViewController.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 10/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import UIKit
import Stripe
import MBProgressHUD

class FPPayWithPaymentCardViewController: UIViewController {
    
    private var paymentCardDetailsField: STPPaymentCardTextField!
    private var payButton: UIButton!
    private var processedByStripeLabel: UILabel!
    
    var unableToStartPayment: (() -> Void)?
    var paymentSucceeded: (() -> Void)?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = FPColorPaymentFlowBackground
        
        createPaymentCardDetailsField()
        createPayButton()
        createProcessedByStripeLabel()
    }
    
    private func createPaymentCardDetailsField() {
        paymentCardDetailsField = STPPaymentCardTextField()
        paymentCardDetailsField.postalCodeEntryEnabled = false
        view.addSubview(paymentCardDetailsField)
        paymentCardDetailsField.translatesAutoresizingMaskIntoConstraints = false
        paymentCardDetailsField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        paymentCardDetailsField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        paymentCardDetailsField.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
    }
    
    private func createPayButton() {
        payButton = UIButton()
        payButton.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        payButton.setTitle("Pay", for: .normal)
        payButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20.0)
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        view.addSubview(payButton)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        payButton.topAnchor.constraint(equalTo: paymentCardDetailsField.bottomAnchor, constant: 14).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    private func createProcessedByStripeLabel() {
        processedByStripeLabel = UILabel()
        processedByStripeLabel.text = "Your card details will be processed by Stripe."
        processedByStripeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 22.0)
        processedByStripeLabel.textColor = FPColorPaymentFlowMessage
        view.addSubview(processedByStripeLabel)
        processedByStripeLabel.translatesAutoresizingMaskIntoConstraints = false
        processedByStripeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        processedByStripeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        processedByStripeLabel.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 14).isActive = true
    }
    
    override func viewDidLoad() {
        title = "Enter card details"
        paymentCardDetailsField.becomeFirstResponder()
        createPaymentIntent()
    }
    
    private func createPaymentIntent() {
        let checkoutSum = FPCartView.sharedCart().checkoutSum
        PaymentCardProcessor.shared.createPaymentIntent(forCheckoutSum: checkoutSum) { [weak self] didSucceed in
            if !didSucceed {
                self?.unableToStartPayment?()
            }
        }
    }
    
    @objc private func payTapped() {
        let progressHud = MBProgressHUD.showAdded(to: view, animated: false)
        progressHud?.removeFromSuperViewOnHide = true
        progressHud?.labelText = "Performing payment..."
        
        PaymentCardProcessor.shared.performPayment(with: paymentCardDetailsField.cardParams, in: self) { [weak self] paymentResult in
            progressHud?.hide(false)
            switch paymentResult {
            case .canceled:
                FPAlertManager.showMessage("Your card was not charged.", withTitle: "Payment canceled")
            case .error(message: let message):
                FPAlertManager.showMessage(message ?? "Unknown error occurred.", withTitle: "Unable to make payment")
            case .success:
                self?.paymentSucceeded?()
            }
        }
    }

}

extension FPPayWithPaymentCardViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}
