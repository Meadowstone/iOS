//
//  FPPaymentOptionsViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/3/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MessageUI
import MBProgressHUD

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class FPPaymentOptionsViewController: FPRotationViewController {
    
    var didRedirect = false
    
    var balanceCompletionHandler: (() -> Void)!
    
    @IBOutlet var payNowBtn: UIButton!
    @IBOutlet var payLaterBtn: UIButton!
    
    @IBOutlet var button1: UIButton!
    @IBOutlet var button2: UIButton!
    @IBOutlet var button3: UIButton!
    @IBOutlet var button4: UIButton!
    @IBOutlet var button5: UIButton!
    @IBOutlet var button6: UIButton!
    @IBOutlet var button7: UIButton!
    
    @IBOutlet weak var button3explanationLabel: UILabel!
    @IBOutlet weak var button4explanationLabel: UILabel!
    
    var balancePayment = false
    var balanceSum : Double = 0.0
    
    @IBAction func payNowPressed(_ sender: AnyObject?) {
        let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func payLaterPressed(_ sender: AnyObject) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": 4])
    }
    
    
    class func paymentOptionsViewController() -> FPPaymentOptionsViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPPaymentOptionsViewController") as! FPPaymentOptionsViewController
        
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.button3.isHidden = true
        self.button4.isHidden = true
        self.button5.isHidden = true
        
        updateChoices()
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = UIColor.white
        }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(FPPaymentOptionsViewController.cancelPressed)
        )
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
        navigationController!.navigationBar.barStyle = .black
        navigationController!.navigationBar.isTranslucent = false
        
        preferredContentSize = CGSize(width: 640, height: 468)
    }
    
    func updateChoices() {
        button1.setTitle("Pay with Cash", for: .normal)
        button1.tag = FPPaymentMethod.cash.rawValue
        
        button2.setTitle("Pay with Check", for: .normal)
        button2.tag = FPPaymentMethod.check.rawValue
        
        button6.setTitle("Pay with Credit/Debit Card", for: .normal)
        button6.tag = FPPaymentMethod.terminal.rawValue
        
        button7.setTitle("Pay with Venmo", for: .normal)
        button7.tag = FPPaymentMethod.venmo.rawValue
        
        button3.isHidden = true
        button4.isHidden = true
        button5.isHidden = true
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            button3explanationLabel.isHidden = true
            button4explanationLabel.isHidden = true
        }
        
        let payWithPaymentCardTitle = "Pay with Credit/Debit Card"
        
        if let customer = FPCustomer.activeCustomer() {
            if !balancePayment {
                if FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) <= FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) {
                    button3.setTitle("Pay with Balance", for: .normal)
                    button3.tag = FPPaymentMethod.balance.rawValue
                } else {
                    button3.setTitle("Pay Later", for: .normal)
                    button3.tag = FPPaymentMethod.payLater.rawValue
                }
                button3.isHidden = false
                
                button4.setTitle(payWithPaymentCardTitle, for: .normal)
                button4.tag = FPPaymentMethod.paymentCard.rawValue
                button4.isHidden = true
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    button4explanationLabel.text = payWithPaymentCardExplanation()
                    button4explanationLabel.isHidden = false
                }
            }
        } else if FPFarmWorker.activeWorker() == nil {
            button3.setTitle(payWithPaymentCardTitle, for: .normal)
            button3.tag = FPPaymentMethod.paymentCard.rawValue
            button3.isHidden = true
            button3explanationLabel.text = payWithPaymentCardExplanation()
            button3explanationLabel.isHidden = false
        }
    }
    
    private func payWithPaymentCardExplanation() -> String {
        let feePercentageText = String(format: "%.1f%%", FPUser.activeUser()!.farm!.paymentCardProcessor!.transactionFeePercentage)
        let feeFixedText = "$.\(Int(FPUser.activeUser()!.farm!.paymentCardProcessor!.transactionFeeFixed * 100))"
        return """
            Unfortunately we are unable to absorb the credit card bank fees so an additional \
            \(feePercentageText) + \(feeFixedText) will be charged per transaction.
            """
    }
    
    //MARK: - Payment action
    @IBAction func buttonPressed(_ sender: AnyObject?) {
        switch sender!.tag {
        case FPPaymentMethod.cash.rawValue:
            if !balancePayment {
                let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
                vc.mode = 1
                navigationController!.pushViewController(vc, animated: true)
            } else {
                depositSumPayWithCheck(false, checkNumber: nil, transactionToken: nil, last4: nil)
            }
        case FPPaymentMethod.check.rawValue:
            if !balancePayment {
                let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
                vc.mode = 2
                navigationController!.pushViewController(vc, animated: true)
            } else {
                let alert = UIAlertView()
                alert.alertViewStyle = .plainTextInput
                alert.tag = FPPaymentMethod.check.rawValue
                alert.message = "Check number"
                alert.delegate = self
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Submit")
                alert.show()
            }
        case FPPaymentMethod.balance.rawValue:
            let notificationParams: [String : Any] = [
                "method": FPPaymentMethod.balance.rawValue,
                "sumPaid": FPCartView.sharedCart().checkoutSum
            ]
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification),
                                            object: notificationParams)
        case FPPaymentMethod.payLater.rawValue:
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": 4])
        case FPPaymentMethod.paymentCard.rawValue:
            let payWithPaymentCardViewController = FPPayWithPaymentCardViewController()
            let totalPrice = PaymentCardController.shared.priceWithAddedFees(forPrice: FPCartView.sharedCart().checkoutSum)
            payWithPaymentCardViewController.price = totalPrice
            payWithPaymentCardViewController.paymentSucceeded = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
                let notificationParams: [String : Any] = [
                    "method": FPPaymentMethod.paymentCard.rawValue,
                    "sumPaid": totalPrice
                ]
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification),
                                                object: notificationParams)
            }
            navigationController?.pushViewController(payWithPaymentCardViewController, animated: true)
        case FPPaymentMethod.terminal.rawValue:
            let amount = !balancePayment ? FPCartView.sharedCart().checkoutSum : balanceSum 
            let price = PaymentCardController.shared.priceWithAddedFees(
                forPrice: amount
            )
            
            let viewController = FPPayWithTerminalViewController(
                price: price
            ) { [weak self] in
                guard let self = self else { return }
                
                if !self.balancePayment {
                    self.navigationController?.popViewController(
                        animated: true
                    )
                    
                    let notificationParams: [String : Any] = [
                        "method": FPPaymentMethod.terminal.rawValue,
                        "sumPaid": price
                    ]
                    
                    NotificationCenter.default.post(
                        name: Notification.Name(
                            rawValue: FPPaymentMethodSelectedNotification
                        ),
                        object: notificationParams
                    )
                } else {
                    self.depositSumPayWithCheck(
                        false,
                        checkNumber: nil,
                        transactionToken: nil,
                        last4: nil
                    )
                }
            }
            
            navigationController?.pushViewController(
                viewController,
                animated: true
            )
        case FPPaymentMethod.venmo.rawValue:
            let price = !balancePayment ? FPCartView.sharedCart().checkoutSum : balanceSum
            let viewController = FPPayWithVenmoViewController(
                price: price,
                balancePayment: balancePayment,
                completion: { [weak self] in
                    guard let self = self else { return }
                    
                    if !self.balancePayment {
                        NotificationCenter.default.post(
                            name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification),
                            object: ["method": FPPaymentMethod.venmo.rawValue]
                        )
                    } else {
                        self.depositSumPayWithCheck(
                            false,
                            checkNumber: nil,
                            transactionToken: nil,
                            last4: nil
                        )
                    }
                }
            )
            navigationController?.pushViewController(viewController, animated: true)
        default:
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FPCustomer.activeCustomer() == nil && !didRedirect {
            didRedirect = true
            //payLaterBtn.enabled = false
            //payNowPressed(nil)
        }
        updateChoices()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            navigationItem.title = ""
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !self.balancePayment {
            navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        } else {
            navigationItem.title = "Balance payment: $" + FPCurrencyFormatter.printableCurrency(balanceSum)
        }
    }
    
    @objc func cancelPressed() {
        if !balancePayment {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": FPPaymentMethod.cancelled.rawValue])
        } else {
            // Return to balance payment sum editing
            _ = navigationController?.popViewController(animated: true)
        }
    }
    //MARK: - Balance payment
    func depositSumPayWithCheck(_ isCheck: Bool, checkNumber: String?, transactionToken: String?, last4: String?) {
        var hud: MBProgressHUD!
        let completion = { [weak self] (errMsg: String?) -> Void in
            hud.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                var message = ""
                if isCheck {
                    if FPFarmWorker.activeWorker() == nil {
                        message = "Please drop your check into the container labeled \"Cash/Check Box.\"\nYou will receive an email receipt of your deposit."
                    }
                } else { // cash
                    if FPFarmWorker.activeWorker() == nil {
                        message = "Please drop your cash into the container labeled \"Cash/Check Box.\"\nYou will receive an email receipt of your deposit."
                    }
                }
                
                let alertController = UIAlertController(title: "Deposit successfull!", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    self?.balanceCompletionHandler()
                })
                self?.present(alertController, animated: true)
            }
        }
        hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud.removeFromSuperViewOnHide = true
        hud.labelText = "Processing"
        FPServer.sharedInstance.balanceDepositWithSum(
            self.balanceSum,
            getCredit: nil,
            isCheck: isCheck,
            checkNumber: checkNumber,
            transactionToken: transactionToken,
            last4: last4,
            completion: completion
        )
    }

}

extension FPPaymentOptionsViewController: UIAlertViewDelegate {
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == FPPaymentMethod.check.rawValue && buttonIndex == 1 {
             let text = alertView.textField(at: 0)!.text
             depositSumPayWithCheck(true, checkNumber: text, transactionToken: nil, last4: nil)
         }
    }
    
}
