//
//  FPCashCheckViewController.swift
//  FarmPOS
//
//  Created by GL-Office on 22.07.14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPCashCheckViewController: FPRotationViewController {
    
    var numPadView: FPNumPadView!
    var paymentMethod = FPPaymentMethod.cash
    var isChangeBack = true
    var showCancel = false
    var change = 0.0
    var sumPaid = 0.0
    
    var mode : Int = 0
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sumTextField: UITextField!
    @IBOutlet var cashCheckSegmented: UISegmentedControl!
    @IBOutlet var changeSegmented: UISegmentedControl!
    @IBOutlet var changeLabel: UILabel!
    @IBOutlet var paymentMethodLabel: UILabel!
    @IBOutlet var numPadPlaceholderView: UIView!
    @IBOutlet var payBtn: UIButton!
    
    @IBAction func segmentedValueChanged(_ sender: AnyObject) {
        if sender === cashCheckSegmented {
            let text = ""
            var placeholder = ""
            var useDecimal = true
            paymentMethod = cashCheckSegmented.selectedSegmentIndex == 0 ? .cash : .check
            if paymentMethod == FPPaymentMethod.cash {
                if FPFarmWorker.activeWorker() != nil {
                    changeLabel.isHidden = false
                    if FPCustomer.activeCustomer() != nil {
                        changeSegmented.isHidden = false
                    } else {
                        changeSegmented.isHidden = true
                    }
                }
                placeholder = "Enter sum"
            } else {
                changeLabel.isHidden = true
                changeSegmented.isHidden = true
                change = 0.0
                placeholder = "Check number (optional)"
                useDecimal = false
            }
            
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                numPadView.textField.text = text
                numPadView.textField.placeholder = placeholder
                numPadView.textField.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
                numPadView.shouldShowDot = useDecimal
            } else {
                sumTextField.text = text
                sumTextField.placeholder = placeholder
                sumTextField.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
                sumTextField.keyboardType = useDecimal ? .decimalPad : .numberPad
            }
        } else {
            isChangeBack = changeSegmented.selectedSegmentIndex == 0
        }
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            numPadView.editingChangedHandler!(numPadView.textField.text!)
        } else {
            updateSumWithText(sumTextField.text!)
        }
    }
    
    @IBAction func payPressed(_ sender: AnyObject) {
        let sPaid = FPCurrencyFormatter.roundCrrency(sumPaid)
        let sPurchase = FPCurrencyFormatter.roundCrrency(FPCartView.sharedCart().checkoutSum)
        if sPaid < sPurchase || sPaid <= 0.0 {
            FPAlertManager.showMessage("Payment sum can not be smaller than the purchase sum.", withTitle: "Error")
            return
        }
        
        var method = 2
        var checkNumber = ""
        if paymentMethod == .check {
            method = 3
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                checkNumber = numPadView.textField.text!
            } else {
                checkNumber = sumTextField.text!
            }
            sumPaid = FPCartView.sharedCart().checkoutSum
            change = 0.00
        }
        
        if FPCustomer.activeCustomer() != nil {
            let vc = FPPaymentConfirmViewController.paymentConfirmViewControllerWithSumPaid(sumPaid, paymentMethod: paymentMethod, checkNumber: checkNumber, change: change)
            navigationController!.pushViewController(vc, animated: true)
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": method, "checkNumber": checkNumber, "sumPaid": sumPaid - change, "change": change])
        }
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
        updateSumWithText(sender.text!)
    }
    
    class func cashCheckViewControllerShowCancel(_ showCancel: Bool) -> FPCashCheckViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPCashCheckViewController") as! FPCashCheckViewController
        vc.showCancel = showCancel
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        } else {
            navigationItem.title = "$" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        }
        navigationController!.navigationBar.barStyle = .black
        navigationController!.navigationBar.isTranslucent = false
        preferredContentSize = CGSize(width: 640, height: 468)
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            let editingHandler = { [weak self] (string: String) -> Void in
                self!.updateSumWithText(string)
            }
            //            numPadView = FPNumPadView.numPadViewForPounds(false, editingHanlder: editingHandler, maxInputCount: Int.max, shouldShowDot: true)
            numPadView = FPNumPadView.numPadViewForPaymentWithEditingHandler(editingHandler)
            numPadView.textField.placeholder = "Enter Sum"
            numPadPlaceholderView.addSubview(numPadView)
        } else {
            NotificationCenter.default.addObserver(self, selector: #selector(FPCashCheckViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(FPCashCheckViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
            
            sumTextField.placeholder = "Enter Sum"
            sumTextField.becomeFirstResponder()
        }
        
        if showCancel {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPCashCheckViewController.cancelPressed))
        }
        
        self.updateRightBarButtonItem()
        
        cashCheckSegmented.tintColor = UINavigationBar.appearance().barTintColor
        cashCheckSegmented.selectedSegmentIndex = 0
        
        changeSegmented.tintColor = cashCheckSegmented.tintColor
        changeSegmented.selectedSegmentIndex = 0
        changeSegmented.isHidden = FPFarmWorker.activeWorker() == nil || (FPFarmWorker.activeWorker() != nil && FPCustomer.activeCustomer() == nil)
        changeLabel.isHidden = FPFarmWorker.activeWorker() == nil
        
        // Check 'override' mode
        if mode == 1 {
            // Force cash payment
            cashCheckSegmented.isHidden = true
            cashCheckSegmented.selectedSegmentIndex = 0
            paymentMethodLabel?.isHidden = true
        } else if mode == 2 {
            // Force check payment
            cashCheckSegmented.selectedSegmentIndex = 1;
            segmentedValueChanged(cashCheckSegmented)
            cashCheckSegmented.isHidden = true
            paymentMethodLabel?.isHidden = true
        }
        // Check applicable balance
        if let customer = FPCustomer.activeCustomer(), FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) > 0 {
            var balance = FPCartView.sharedCart().sumWithTax
            if FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) < FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                balance = customer.balance
            } else if FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) >= FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                balance = 0.00
            }
            FPCartView.sharedCart().applicableBalance = balance
            self.updateRightBarButtonItem()
        }
    }
    
    func updateRightBarButtonItem() {
        if let user = FPUser.activeUser(), user.farm != nil && FPCustomer.activeCustomer() != nil {
            var item: UIBarButtonItem!
            if self.navigationItem.rightBarButtonItem != nil {
                item = self.navigationItem.rightBarButtonItem
            } else {
                item = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(FPCashCheckViewController.applyBalancePressed))
                self.navigationItem.rightBarButtonItem = item
            }
            item.title = "Applicable Balance: $\(FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().applicableBalance))"
            // Check if display is needed
            if FPCurrencyFormatter.intCurrencyRepresentation(FPCustomer.activeCustomer()!.balance) <= 0 {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
    }
    
    @objc func applyBalancePressed() {
        let vc = FPApplyBalanceViewController.applyBalanceViewControllerWithBalanceSelectedHandler {[weak self] (balance) -> Void in
            FPCartView.sharedCart().applicableBalance = balance
            self!.updateRightBarButtonItem()
            // Update change
            if self!.isChangeBack {
                self!.change = self!.sumPaid - FPCartView.sharedCart().checkoutSum
            } else {
                self!.change = 0.0
            }
            self!.change = max(self!.change, 0.0)
            
            self!.changeLabel.text = "CHANGE DUE: $" + FPCurrencyFormatter.printableCurrency(self!.change)
            self!.navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
            _ = self!.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func cancelPressed() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": FPPaymentMethod.cancelled.rawValue])
    }
    
    func updateSumWithText(_ string: String) {
        var string = string
        if string == "" {
            string = "0"
        }
        if paymentMethod == .cash {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "en_US")
            nf.numberStyle = .decimal
            nf.maximumFractionDigits = 2
            sumPaid = nf.number(from: string) as! Double
        } else {
            sumPaid = FPCartView.sharedCart().checkoutSum
        }
        
        if isChangeBack {
            change = sumPaid - FPCartView.sharedCart().checkoutSum
        } else {
            change = 0.0
        }
        change = max(change, 0.0)
        
        changeLabel.text = "CHANGE DUE: $" + FPCurrencyFormatter.printableCurrency(change)
    }
    
    //MARK: Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if var kbRect = (note.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            kbRect = FPAppDelegate.instance().window!.convert(kbRect, to: view)
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    @objc func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
}
