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
    
    private var thankYouMessageLabel: UILabel!
    private var optionsStackView: UIStackView!
    private var paymentExplanationLabel: UILabel!
    
    var cancelTapped: (() -> Void)?
    var errorWhileContactingFarmServer: ((String) -> Void)?
    var balanceUpdated: (() -> Void)?
    private var optionsForViews = [UIView : FPCustomerManageBalanceOption]()
    
    override func loadView() {
        preferredContentSize = .init(width: 640, height: 512)
        view = UIView()
        view.backgroundColor = FPColorPaymentFlowBackground
        createOptionsStackView()
        createOptionViews(from: FPUser.activeUser()!.farm!.customerManageBalanceOptions)
        createThankYouMessageLabel()
        createPaymentExplanationLabel()
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
    
    private func createThankYouMessageLabel() {
        thankYouMessageLabel = UILabel()
        thankYouMessageLabel.text = "Thank you for supporting Meadowstone Farm and local agriculture!"
        thankYouMessageLabel.numberOfLines = 0
        thankYouMessageLabel.textAlignment = .center
        thankYouMessageLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        thankYouMessageLabel.textColor = FPColorPaymentFlowMessage
        view.addSubview(thankYouMessageLabel)
        thankYouMessageLabel.translatesAutoresizingMaskIntoConstraints = false
        thankYouMessageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        thankYouMessageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        thankYouMessageLabel.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        thankYouMessageLabel.bottomAnchor.constraint(equalTo: optionsStackView.topAnchor).isActive = true
    }
    
    private func createPaymentExplanationLabel() {
        paymentExplanationLabel = UILabel()
        paymentExplanationLabel.text = """
            You can only update your balance with a credit card on this page.  \
            If you would like to add to your account with cash or check, \
            please place either in the cash box and we’ll add it ASAP.
            """
        paymentExplanationLabel.numberOfLines = 0
        paymentExplanationLabel.textAlignment = .center
        paymentExplanationLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        paymentExplanationLabel.textColor = FPColorPaymentFlowMessage
        view.addSubview(paymentExplanationLabel)
        paymentExplanationLabel.translatesAutoresizingMaskIntoConstraints = false
        paymentExplanationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20).isActive = true
        paymentExplanationLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20).isActive = true
        paymentExplanationLabel.topAnchor.constraint(equalTo: optionsStackView.bottomAnchor).isActive = true
        paymentExplanationLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
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
        guard let option = optionsForViews[sender]
        else { return }
        
        var vc: FPPayWithTerminalViewController?
        vc = FPPayWithTerminalViewController(
            price: option.price
        ) {
            let progressHud = MBProgressHUD.showAdded(
                to: vc!.view,
                animated: false
            )
            progressHud?.removeFromSuperViewOnHide = true
            progressHud?.labelText = "Updating balance..."
            
            FPServer.sharedInstance.balanceDepositWithSum(
                option.price,
                getCredit: option.balanceAdded,
                isCheck: false,
                checkNumber: nil,
                transactionToken: nil,
                last4: nil,
                completion: { [weak self] errorMessage in
                    progressHud?.hide(false)
                    if let errorMessage = errorMessage {
                        self?.errorWhileContactingFarmServer?(errorMessage)
                    } else {
                        self?.balanceUpdated?()
                    }
                })
        }
        
        navigationController?.pushViewController(
            vc!,
            animated: true
        )
    }
    
}
