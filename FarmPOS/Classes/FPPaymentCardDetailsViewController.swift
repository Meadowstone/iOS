//
//  FPPaymentCardDetailsViewController.swift
//  Farmstand Cart
//
//  Created by Denis Mendica on 10/09/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import UIKit
import Stripe

class FPPaymentCardDetailsViewController: UIViewController {
    
    var stackView: UIStackView!
    var paymentCardDetailsField: STPPaymentCardTextField!
    var payButton: UIButton!
    
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
    
    @objc func payTapped() {
        dismiss(animated: true)
    } 

}
