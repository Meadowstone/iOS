//
//  FPPaymentCardDetailsViewController.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 10/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import UIKit
import Stripe
import MBProgressHUD

class FPPayWithPaymentCardViewController: UIViewController {
    
    private var stackView: UIStackView!
    private var paymentCardDetailsField: STPPaymentCardTextField!
    private var payButton: UIButton!
    
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
        paymentCardDetailsField.postalCodeEntryEnabled = false
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
        PaymentCardProcessor.shared.createPaymentIntent { [weak self] didSucceed in
            if !didSucceed {
                self?.unableToStartPayment?()
            }
        }
    }
    
    @objc func payTapped() {
        let progressHud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        progressHud?.removeFromSuperViewOnHide = true
        progressHud?.labelText = "Performing payment..."
        
        PaymentCardProcessor.shared.performPayment(with: paymentCardDetailsField.cardParams, in: self) { [weak self] paymentResult in
            progressHud?.hide(false)
            switch paymentResult {
            case .success:
                self?.paymentSucceeded?()
            case .error(message: let message):
                FPAlertManager.showMessage(message ?? "Unknown error occurred", withTitle: "Payment failed")
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
