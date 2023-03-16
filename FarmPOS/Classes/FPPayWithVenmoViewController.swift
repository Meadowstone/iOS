//
//  FPPayWithVenmoViewController.swift
//  Farm POS
//
//  Created by Denis Mendica on 09.03.2023..
//  Copyright © 2023 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPPayWithVenmoViewController: UIViewController {
    
    private let price: Double
    private let balancePayment: Bool
    private let completion: (() -> Void)
    
    private var priceLabel: UILabel!
    private var qrCodeImageView: UIImageView!
    private var paymentSubmittedButton: UIButton!
    
    init(price: Double, balancePayment: Bool, completion: @escaping (() -> Void)) {
        self.price = price
        self.balancePayment = balancePayment
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = UIView()
        view.backgroundColor = FPColorPaymentFlowBackground
        
        createPurchaseAmountLabel()
        createQRCodeImageView()
        createPaymentSubmittedButton()
    }
    
    private func purchaseAmountAttributedString() -> NSAttributedString {
        let meaningText = !balancePayment ? "Purchase Amount" : "Balance Payment"
        let dollarsText = "$" + FPCurrencyFormatter.printableCurrency(price)
        let attributedString = NSMutableAttributedString(string: "\(meaningText): \(dollarsText)")
        attributedString.addAttribute(
            .foregroundColor,
            value: FPColorGreen,
            range: (attributedString.string as NSString)
                .range(of: dollarsText, options: .backwards)
        )
        return attributedString
    }
    
    private func createPurchaseAmountLabel() {
        priceLabel = UILabel()
        priceLabel.font = UIFont(name: "HelveticaNeue-Light", size: 22)
        priceLabel.textColor = FPColorPaymentFlowMessage
        priceLabel.attributedText = purchaseAmountAttributedString()
        
        view.addSubview(priceLabel)
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        priceLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
    }
    
    private func createQRCodeImageView() {
        qrCodeImageView = UIImageView(image: .init(named: "venmo_qr_code"))
        
        view.addSubview(qrCodeImageView)
        qrCodeImageView.translatesAutoresizingMaskIntoConstraints = false
        qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        qrCodeImageView.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 16).isActive = true
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
        completion()
    }
}
