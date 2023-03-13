//
//  FPPayWithVenmoViewController.swift
//  Farm POS
//
//  Created by Denis Mendica on 09.03.2023..
//  Copyright © 2023 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPPayWithVenmoViewController: UIViewController {
    
    private var purchaseAmountLabel: UILabel!
    private var qrCodeImageView: UIImageView!
    private var paymentSubmittedButton: UIButton!
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = FPColorPaymentFlowBackground
        
        createPurchaseAmountLabel()
        createQRCodeImageView()
        createPaymentSubmittedButton()
    }
    
    private func purchaseAmountAttributedString() -> NSAttributedString {
        let dollarsText = "$" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        let attributedString = NSMutableAttributedString(string: "Purchase Amount: \(dollarsText)")
        attributedString.addAttribute(
            .foregroundColor,
            value: FPColorGreen,
            range: (attributedString.string as NSString)
                .range(of: dollarsText, options: .backwards)
        )
        return attributedString
    }
    
    private func createPurchaseAmountLabel() {
        purchaseAmountLabel = UILabel()
        purchaseAmountLabel.font = UIFont(name: "HelveticaNeue-Light", size: 22)
        purchaseAmountLabel.textColor = FPColorPaymentFlowMessage
        purchaseAmountLabel.attributedText = purchaseAmountAttributedString()
        
        view.addSubview(purchaseAmountLabel)
        purchaseAmountLabel.translatesAutoresizingMaskIntoConstraints = false
        purchaseAmountLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        purchaseAmountLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
    }
    
    private func createQRCodeImageView() {
        qrCodeImageView = UIImageView(image: .init(named: "venmo_qr_code"))
        
        view.addSubview(qrCodeImageView)
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        qrCodeImageView.topAnchor.constraint(equalTo: purchaseAmountLabel.bottomAnchor, constant: 16).isActive = true
    }
    
    private func createPaymentSubmittedButton() {
        paymentSubmittedButton = UIButton()
        paymentSubmittedButton.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        paymentSubmittedButton.setTitle("Payment submitted", for: .normal)
        paymentSubmittedButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20)
        paymentSubmittedButton.addTarget(self, action: #selector(paymentSubmittedTapped), for: .touchUpInside)
        
        view.addSubview(paymentSubmittedButton)
        paymentSubmittedButton.translatesAutoresizingMaskIntoConstraints = false
        paymentSubmittedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        paymentSubmittedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        paymentSubmittedButton.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 20).isActive = true
        paymentSubmittedButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
    
    @objc private func paymentSubmittedTapped() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification),
            object: ["method": FPPaymentMethod.venmo.rawValue]
        )
    }
}
