//
//  FPManageBalanceViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/15/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPManageBalanceViewController: FPRotationViewController, UIAlertViewDelegate {
    
    var completionHandler: (() -> Void)!
    var numPadView: FPNumPadView!
    var sum: Double = 0.0
    
    @IBOutlet var currentBalanceLabel: UILabel!
    @IBOutlet var balanceAfterPurchaseLabel: UILabel!
    @IBOutlet var numPadPlaceholderView: UIView!
    @IBOutlet weak var sumTextField: UITextField!
    
    @IBAction func payPressed(_ sender: AnyObject) {
        if sum <= 0.0 {
            return
        }
        
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPPaymentOptionsViewController") as! FPPaymentOptionsViewController
        vc.balancePayment = true
        vc.balanceSum = sum
        // Pass completion handler
        vc.balanceCompletionHandler = completionHandler
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if (sender.text! as NSString).length > 0 {
            let text = (sender.text! as NSString).substring(from: (sender.text! as NSString).length - 1)
            sender.text = (sender.text! as NSString).substring(to: (sender.text! as NSString).length - 1)
            let t = FPInputValidator.preprocessCurrencyText(text, relativeTo: sender.text!)
            if FPInputValidator.shouldAddString(t, toString: sender.text!, maxInputCount: Int.max, isDecimal: true) {
                sender.text = sender.text! + t
            }
        }
        processText(sender.text!)
    }
    
    
    class func manageBalanceViewControllerWithCompletion(_ completion: @escaping () -> Void) -> FPManageBalanceViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPManageBalanceViewController") as! FPManageBalanceViewController
        vc.completionHandler = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "\(FPCustomer.activeCustomer()!.name): Manage balance"
        
        currentBalanceLabel.text = "CURRENT BALANCE $\(FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.balance))"
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            let editingHandler = { [weak self] (text: String) -> Void in
                self!.processText(text)
            }
            numPadView = FPNumPadView.numPadViewForPounds(false, maxInputCount: Int.max, shouldShowDot: true, editingHanlder: editingHandler)
            numPadView.textField.placeholder = "Enter Sum"
            numPadView.textField.attributedPlaceholder = NSAttributedString(string : numPadView.textField.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            numPadPlaceholderView.addSubview(numPadView)
            
            preferredContentSize = CGSize(width: 640.0, height: 468.0)
        }
        
        if sumTextField != nil {
            if let placeholder = sumTextField.placeholder {
                sumTextField.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            }
        }
        
        processText("0")
    }
    
    func processText(_ text: String) {
        if (text as NSString).length == 0 {
            sum = 0.0
        } else {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "en_US")
            let n: NSNumber? = nf.number(from: text)
            var d = 0.0
            if n != nil {
                d = n!.doubleValue
            }
            sum = d
        }
        
        if let customer = FPCustomer.activeCustomer() {
            balanceAfterPurchaseLabel.text = "BALANCE AFTER PURCHASE: $\(FPCurrencyFormatter.printableCurrency(sum + customer.balance))"
        } else {
            balanceAfterPurchaseLabel.text = "No customer found. Please re-login."
        }
    }
    
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
                let alert = UIAlertView()
                alert.tag = 1
                alert.title = "Deposit successfull!"
                alert.message = message
                alert.delegate = self
                alert.addButton(withTitle: "OK")
                alert.show()
            }
        }
        hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud.removeFromSuperViewOnHide = true
        hud.labelText = "Processing"
        FPServer.sharedInstance.balanceDepositWithSum(
            sum,
            getCredit: nil,
            isCheck: isCheck,
            checkNumber: checkNumber,
            transactionToken: transactionToken,
            last4: last4,
            completion: completion
        )
    }
    
    // UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 1 {
            completionHandler()
        } else if alertView.tag == 2 && buttonIndex == 1 {
            let text = alertView.textField(at: 0)!.text
            depositSumPayWithCheck(true, checkNumber: text, transactionToken: nil, last4: nil)
        }
    }
    
}
