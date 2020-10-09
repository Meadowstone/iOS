//
//  FPCustomerManageBalanceViewController.swift
//  Farm POS
//
//  Created by Denis Mendica on 07/10/2020.
//  Copyright © 2020 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCustomerManageBalanceViewController: UIViewController {
    
    private var optionsStackView: UIStackView!
    
    var cancelTapped: (() -> Void)?
    var errorWhileContactingFarmServer: ((String) -> Void)?
    var balanceUpdated: (() -> Void)?
    private var optionsForViews = [UIView : FPCustomerManageBalanceOption]()
    
    override func loadView() {
        preferredContentSize = .init(width: 640, height: 512)
        view = UIView()
        view.backgroundColor = FPColorPaymentFlowBackground
        createOptionsStackView()
        createOptionViews(from: FPCustomerManageBalanceOption.currentOptions)
    }
    
    override func viewDidLoad() {
        setupNavigationBar()
    }
    
    private func createOptionsStackView() {
        optionsStackView = UIStackView()
        optionsStackView.axis = .vertical
        optionsStackView.spacing = 8
        view.addSubview(optionsStackView)
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        optionsStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        optionsStackView.widthAnchor.constraint(equalToConstant: 350).isActive = true
    }
    
    private func createOptionViews(from options: [FPCustomerManageBalanceOption]) {
        for option in options {
            let optionView = createOptionView(from: option)
            optionsForViews[optionView] = option
            optionsStackView.addArrangedSubview(optionView)
        }
    }
    
    private func createOptionView(from option: FPCustomerManageBalanceOption) -> UIView {
        let optionButton = UIButton()
        let priceText = "$\(FPCurrencyFormatter.printableCurrency(option.price))"
        let balanceAddedText = "$\(FPCurrencyFormatter.printableCurrency(option.balanceAdded))"
        optionButton.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        optionButton.setTitle("Pay \(priceText), get \(balanceAddedText)", for: .normal)
        optionButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20)
        optionButton.addTarget(self, action: #selector(optionViewTapped(sender:)), for: .touchUpInside)
        optionButton.translatesAutoresizingMaskIntoConstraints = false
        optionButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return optionButton
    }
    
    private func setupNavigationBar() {
        title = "Manage balance"
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
    }
    
    @objc private func cancelButtonTapped() {
        cancelTapped?()
    }
    
    @objc private func optionViewTapped(sender: UIButton) {
        guard let option = optionsForViews[sender] else { return }
        let payWithPaymentCardViewController = FPPayWithPaymentCardViewController()
        payWithPaymentCardViewController.price = option.price
        payWithPaymentCardViewController.paymentSucceeded = { [weak self] in
            FPServer.sharedInstance.balanceDepositWithSum(
                option.price,
                getCredit: option.balanceAdded,
                isCheck: false,
                checkNumber: nil,
                transactionToken: nil,
                last4: nil,
                completion: { [weak self] errorMessage in
                    if let errorMessage = errorMessage {
                        self?.errorWhileContactingFarmServer?(errorMessage)
                    } else {
                        self?.balanceUpdated?()
                    }
                })
        }
        navigationController?.pushViewController(payWithPaymentCardViewController, animated: true)
    }
    
}
