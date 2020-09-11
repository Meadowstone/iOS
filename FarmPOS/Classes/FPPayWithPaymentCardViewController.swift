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
        view.backgroundColor = FPColorPaymentFlowBackground
        
        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 14
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50).isActive = true
        
        paymentCardDetailsField = STPPaymentCardTextField()
        paymentCardDetailsField.postalCodeEntryEnabled = false
        stackView.addArrangedSubview(paymentCardDetailsField)
        
        payButton = UIButton()
        payButton.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        payButton.setTitle("Pay", for: .normal)
        payButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20.0)
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        stackView.addArrangedSubview(payButton)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    override func viewDidLoad() {
        title = "Enter card details"
        paymentCardDetailsField.becomeFirstResponder()
        createPaymentIntent()
    }
    
    private func createPaymentIntent() {
        PaymentCardProcessor.shared.createPaymentIntent { [weak self] didSucceed in
            if !didSucceed {
                self?.unableToStartPayment?()
            }
        }
    }
    
    @objc func payTapped() {
        let progressHud = MBProgressHUD.showAdded(to: view, animated: false)
        progressHud?.removeFromSuperViewOnHide = true
        progressHud?.labelText = "Performing payment..."
        
        PaymentCardProcessor.shared.performPayment(with: paymentCardDetailsField.cardParams, in: self) { [weak self] paymentResult in
            progressHud?.hide(false)
            switch paymentResult {
            case .error(message: let message):
                FPAlertManager.showMessage(message ?? "Unknown error occurred.", withTitle: "Unable to make payment")
            case .canceled:
                break
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
