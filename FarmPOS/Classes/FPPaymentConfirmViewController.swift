//
//  FPPaymentConfirmViewController.swift
//  FarmPOS
//
//  Created by GL-Office on 22.07.14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPPaymentConfirmViewController: FPRotationViewController {
    
    var sumPaid: Double!
    var paymentMethod: FPPaymentMethod!
    var checkNumber = ""
    var change: Double!

    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var contentLabelHeightConstraint: NSLayoutConstraint!
    
    @IBAction func backPressed(_ sender: AnyObject) {
        navigationController!.popViewController(animated: true)
    }
    
    @IBAction func confirmPressed(_ sender: AnyObject) {
        var method = 2
        if paymentMethod == FPPaymentMethod.check {
            method = 3
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": method, "checkNumber": checkNumber, "sumPaid": sumPaid - change, "change": change!])
    }
    
    
    class func paymentConfirmViewControllerWithSumPaid(_ sumPaid: Double, paymentMethod: FPPaymentMethod, checkNumber: String, change: Double) -> FPPaymentConfirmViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPPaymentConfirmViewController") as! FPPaymentConfirmViewController
        vc.sumPaid = sumPaid
        vc.paymentMethod = paymentMethod
        vc.checkNumber = checkNumber
        vc.change = change
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Confirm purchase"
        preferredContentSize = CGSize(width: 640, height: 468)
        
        let contentAttrText = NSMutableAttributedString()
        
        let amountText = "$" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        let amountAttrText = NSMutableAttributedString(string: "Purchase Amount: \(amountText)")
        amountAttrText.addAttribute(.foregroundColor, value: FPColorGreen, range: (amountAttrText.string as NSString).range(of: amountText, options: .backwards))
        contentAttrText.append(amountAttrText)
        
        let paidText = "$" + FPCurrencyFormatter.printableCurrency(sumPaid)
        let paidAttrText = NSMutableAttributedString(string: "\nCash/Check Paid: \(paidText)")
        paidAttrText.addAttribute(.foregroundColor, value: FPColorGreen, range: (paidAttrText.string as NSString).range(of: paidText, options: .backwards))
        contentAttrText.append(paidAttrText)
        
        let sPaid = FPCurrencyFormatter.roundCrrency(sumPaid)
        let sPurchase = FPCurrencyFormatter.roundCrrency(FPCartView.sharedCart().checkoutSum)
        if sPaid == sPurchase {
            contentAttrText.append(NSAttributedString(string: "\n\nYou are paying the exact amount of your purchase of $\(FPCurrencyFormatter.printableCurrency(sumPaid)) by \(paymentMethod.toString()). Please press Confirm if correct or Back to change."))
        } else if sPaid > sPurchase {
            if change > 0.0 {
                contentAttrText.append(NSAttributedString(string: "\n\nCustomer has paid $\(FPCurrencyFormatter.printableCurrency(sumPaid)) by \(paymentMethod.toString()). Amount of change due is: $\(FPCurrencyFormatter.printableCurrency(change)). Please press Confirm if correct or Back to change."))
            } else {
                let leftoverText = "$" + FPCurrencyFormatter.printableCurrency(sumPaid - FPCartView.sharedCart().checkoutSum)
                let leftoverAttrText = NSMutableAttributedString(string: "\n\nAmount Leftover For Credit: \(leftoverText)")
                leftoverAttrText.addAttribute(.foregroundColor, value: FPColorGreen, range: (leftoverAttrText.string as NSString).range(of: leftoverText, options: .backwards))
                contentAttrText.append(leftoverAttrText)
                
                let balanceText = "$" + FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.balance)
                let balanceAttrText = NSMutableAttributedString(string: "\nAccount Balance Before Credit: \(balanceText)")
                balanceAttrText.addAttribute(.foregroundColor, value: FPColorGreen, range: (balanceAttrText.string as NSString).range(of: balanceText, options: .backwards))
                contentAttrText.append(balanceAttrText)
                
                let balanceAfterText = "$" + FPCurrencyFormatter.printableCurrency((FPCustomer.activeCustomer()!.balance) + (sumPaid - FPCartView.sharedCart().checkoutSum))
                let balanceAfterAttrText = NSMutableAttributedString(string: "\nAccount Balance After Credit: \(balanceAfterText)")
                balanceAfterAttrText.addAttribute(.foregroundColor, value: FPColorGreen, range: (balanceAfterAttrText.string as NSString).range(of: balanceAfterText, options: .backwards))
                contentAttrText.append(balanceAfterAttrText)
                
                contentAttrText.append(NSAttributedString(string: "\n\nYou are paying $\(FPCurrencyFormatter.printableCurrency(sumPaid)) by \(paymentMethod.toString()). This amount is more than your purchase price and a credit will be issued to your account for future purchases. Please press Confirm if correct or Back to change."))
            }
        }
        
        contentLabel.attributedText = contentAttrText
        contentLabelHeightConstraint.constant = contentLabel.sizeThatFits(CGSize(width: contentLabel.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height
    }

}
