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
    private var emailTextField: UITextField!
    private var emailExplanationLabel: UILabel!
    private var payButton: UIButton!
    private var processedByStripeLabel: UILabel!
    
    var price: Double?
    var paymentSucceeded: (() -> Void)?
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = FPColorPaymentFlowBackground
        
        createPaymentCardDetailsField()
        createEmailTextField()
        createEmailExplanationLabel()
        createPayButton()
        createProcessedByStripeLabel()
    }
    
    private func createPaymentCardDetailsField() {
        paymentCardDetailsField = STPPaymentCardTextField()
        paymentCardDetailsField.postalCodeEntryEnabled = false
        paymentCardDetailsField.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
        paymentCardDetailsField.placeholderColor = FPColorPaymentFlowPlaceholder
        paymentCardDetailsField.delegate = self
        view.addSubview(paymentCardDetailsField)
        paymentCardDetailsField.translatesAutoresizingMaskIntoConstraints = false
        paymentCardDetailsField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        paymentCardDetailsField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        paymentCardDetailsField.topAnchor.constraint(equalTo: view.topAnchor, constant: 14).isActive = true
    }
    
    private func createEmailTextField() {
        emailTextField = UITextField()
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailTextField.keyboardType = .emailAddress
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "E-mail",
            attributes: [
                .font : UIFont(name: "HelveticaNeue-Light", size: 20)!,
                .foregroundColor : FPColorPaymentFlowPlaceholder
            ]   
        )
        emailTextField.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        emailTextField.layer.cornerRadius = paymentCardDetailsField.cornerRadius
        emailTextField.layer.borderColor = paymentCardDetailsField.borderColor?.cgColor
        emailTextField.layer.borderWidth = paymentCardDetailsField.borderWidth
        emailTextField.layer.sublayerTransform = CATransform3DMakeTranslation(12, 0, 0)
        emailTextField.delegate = self
        view.addSubview(emailTextField)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        emailTextField.topAnchor.constraint(equalTo: paymentCardDetailsField.bottomAnchor, constant: 14).isActive = true
        emailTextField.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func createEmailExplanationLabel() {
        emailExplanationLabel = UILabel()
        emailExplanationLabel.text = "If you fill out your e-mail, we'll send you a receipt for this purchase."
        emailExplanationLabel.numberOfLines = 0
        emailExplanationLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        emailExplanationLabel.textColor = FPColorPaymentFlowMessage
        view.addSubview(emailExplanationLabel)
        emailExplanationLabel.translatesAutoresizingMaskIntoConstraints = false
        emailExplanationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        emailExplanationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        emailExplanationLabel.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 4).isActive = true
    }
    
    private func createPayButton() {
        payButton = UIButton()
        payButton.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        payButton.setTitle("Pay $\(FPCurrencyFormatter.printableCurrency(price ?? 0))", for: .normal)
        payButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20)
        payButton.addTarget(self, action: #selector(payTapped), for: .touchUpInside)
        view.addSubview(payButton)
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        payButton.topAnchor.constraint(equalTo: emailExplanationLabel.bottomAnchor, constant: 20).isActive = true
        payButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    private func createProcessedByStripeLabel() {
        processedByStripeLabel = UILabel()
        processedByStripeLabel.text = "Your card details will be processed by Stripe."
        processedByStripeLabel.numberOfLines = 0
        processedByStripeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        processedByStripeLabel.textColor = FPColorPaymentFlowMessage
        view.addSubview(processedByStripeLabel)
        processedByStripeLabel.translatesAutoresizingMaskIntoConstraints = false
        processedByStripeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        processedByStripeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        processedByStripeLabel.topAnchor.constraint(equalTo: payButton.bottomAnchor, constant: 4).isActive = true
    }
    
    override func viewDidLoad() {
        title = "Enter card details"
        paymentCardDetailsField.becomeFirstResponder()
        prefillEmailIfNeeded()
    }
    
    @objc private func payTapped() {
        guard let price = price else { return }
        
        let email = emailTextField.text
        if let email = email, !email.isEmpty, !FPInputValidator.isValid(email: email) {
            FPAlertManager.showMessage("Please enter a valid e-mail address.", withTitle: "Invalid e-mail")
            return
        }
        
        let progressHud = MBProgressHUD.showAdded(to: view, animated: false)
        progressHud?.removeFromSuperViewOnHide = true
        progressHud?.labelText = "Performing payment..."
        
        PaymentCardController.shared.createPaymentIntent(forPrice: price, email: email) { [weak self] didSucceed in
            guard let self = self, didSucceed else {
                progressHud?.hide(false)
                FPAlertManager.showMessage("Please try again later.", withTitle: "Unable to make card payment at the moment")
                return
            }

            PaymentCardController.shared.performPayment(with: self.paymentCardDetailsField.cardParams, in: self) { [weak self] paymentResult in
                switch paymentResult {
                case .canceled:
                    progressHud?.hide(false)
                    FPAlertManager.showMessage("Your card was not charged.", withTitle: "Payment canceled")
                case .error(message: let message):
                    progressHud?.hide(false)
                    FPAlertManager.showMessage(message ?? "Unknown error occurred.", withTitle: "Unable to make payment")
                case .success:
                    self?.view.endEditing(true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in // wait until keyboard is dismissed
                        progressHud?.hide(false)
                        self?.paymentSucceeded?()
                    }
                }
            }
        }
    }
    
    private func prefillEmailIfNeeded() {
        guard let customer = FPCustomer.activeCustomer() else { return }
        emailTextField.text = customer.email
    }

}

extension FPPayWithPaymentCardViewController: STPAuthenticationContext {
    
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
}

extension FPPayWithPaymentCardViewController: STPPaymentCardTextFieldDelegate {
    
    func paymentCardTextFieldWillEndEditing(forReturn textField: STPPaymentCardTextField) {
        emailTextField.becomeFirstResponder()
    }
    
}

extension FPPayWithPaymentCardViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        emailTextField.resignFirstResponder()
        return false
    }
    
}
