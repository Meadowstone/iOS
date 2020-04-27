//
//  FPApplyBalanceViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 12/06/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPApplyBalanceViewController: FPRotationViewController, UIAlertViewDelegate {
    
    var balanceSelectedHandler: ((_ balance: Double) -> Void)!
    var numPadView: FPNumPadView!
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var numPadPlaceholderView: UIView!
    @IBOutlet weak var applyBtn: UIButton!
    @IBOutlet weak var balanceTextField: UITextField!
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if (sender.text! as NSString).length > 0 {
            let text = (sender.text! as NSString).substring(from: (sender.text! as NSString).length - 1)
            sender.text = (sender.text! as NSString).substring(to: (sender.text! as NSString).length - 1)
            let t = FPInputValidator.preprocessCurrencyText(text, relativeTo: sender.text!)
            if FPInputValidator.shouldAddString(t, toString: sender.text!, maxInputCount: Int.max, isDecimal: true) {
                sender.text = sender.text! + t
            }
        }
    }
    
    @IBAction func applyPressed(_ sender: AnyObject) {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        
        var text = ""
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            text = numPadView.textField.text!
        } else {
            text = balanceTextField.text!
        }
        
        if let balance = nf.number(from: text) as? Double {
            if FPCurrencyFormatter.intCurrencyRepresentation(balance) > FPCurrencyFormatter.intCurrencyRepresentation(FPCustomer.activeCustomer()!.balance) {
                FPAlertManager.showMessage("Amount entered is higher than customer's balance", withTitle: "Error")
            } else if FPCurrencyFormatter.intCurrencyRepresentation(balance) > FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                FPAlertManager.showMessage("Amount entered is higher than the purchase cost", withTitle: "Error")
            } else if FPCurrencyFormatter.intCurrencyRepresentation(balance) == FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                FPAlertManager.showMessage("Amount entered is precisely the purchase cost. If you'd like to pay with balance, please return to payment selection options and select Pay With Balance.", withTitle: "Error")
            } else {
                balanceSelectedHandler(balance)
            }
        } else {
            FPAlertManager.showMessage("Enter valid price", withTitle: "Error")
        }
    }
    
    class func applyBalanceViewControllerWithBalanceSelectedHandler(_ balanceSelectedHandler: @escaping (Double) -> Void) -> FPApplyBalanceViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPApplyBalanceViewController") as! FPApplyBalanceViewController
        vc.balanceSelectedHandler = balanceSelectedHandler
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        balanceLabel.text = "CURRENT BALANCE: $" + FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.balance)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            numPadView = FPNumPadView.numPadViewForPaymentWithEditingHandler(nil)
            numPadView.textField.placeholder = "Enter amount"
            numPadPlaceholderView.addSubview(numPadView)
        } else {
            self.balanceTextField.becomeFirstResponder()
        }
        
        if let user = FPUser.activeUser(), user.farm != nil && !user.farm!.allowCreditCardPayments {
            if let ac = FPCustomer.activeCustomer(), FPCurrencyFormatter.intCurrencyRepresentation(ac.balance) >= FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Pay With Balance", style: .plain, target: self, action: #selector(FPApplyBalanceViewController.payWithBalancePressed))
            }
        }
        
        preferredContentSize = CGSize(width: 640, height: 468)
    }
    
    func payWithBalancePressed() {
        UIAlertView(title: "Are you sure you want to pay with balance?", message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Pay With Balance").show()
    }
    
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        let title = alertView.buttonTitle(at: buttonIndex)
        if title == "Pay With Balance" {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": 4])
        }
    }

}
