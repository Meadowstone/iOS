//
//  FPPayNowViewController.swift
//  FarmPOS
//
//  Created by GL-Office on 21.07.14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPPayNowViewController: FPRotationViewController, UIActionSheetDelegate {
    
    @IBOutlet weak var balanceBtn: UIButton!
    @IBOutlet var creditCardBtn: UIButton!
    @IBOutlet var cashCheckBtn: UIButton!
    @IBOutlet var giftCardBtn: UIButton!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var clearBtn: UIButton!
    
    @IBAction func clearPressed(_ sender: AnyObject) {
        FPCartView.sharedCart().applicableBalance = 0.00
        self.updateUI()
    }
    
    @IBAction func balancePressed(_ sender: AnyObject) {
        let vc = FPApplyBalanceViewController.applyBalanceViewControllerWithBalanceSelectedHandler {[weak self] (balance) -> Void in
            FPCartView.sharedCart().applicableBalance = balance
            self!.updateUI()
            _ = self!.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func creditCardPressed(_ sender: AnyObject) {
        if !FPUser.activeUser()!.farm!.canUseCreditCard {
            FPAlertManager.showMessage("This farm is not configured to use credit cards.", withTitle: "Error")
            return
        }
        if !FPServer.sharedInstance.reachabilityManager.isReachable {
            FPAlertManager.showMessage("Credit card payments are temporarily unavailable. Please try again later", withTitle:"")
            return
        }
        if FPCardFlightManager.sharedInstance.statusCode != StatusCode.readerDisconnected {
            let actionSheet = UIActionSheet(title: "Select option", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Swipe Credit Card", "Enter Card / Use Saved")
            actionSheet.tag = 2
            actionSheet.show(in: self.view)
        } else {
            let vc = FPCreateCreditCardViewController.createCreditCardViewControllerWithCardSelectedHandler({ creditCard, transactionToken, last4 in
                let sum = FPCartView.sharedCart().checkoutSum
                var params: Dictionary<String, AnyObject> = ["method": 1 as AnyObject, "sumPaid": sum as AnyObject]
                if let cc = creditCard {
                    if FPCustomer.activeCustomer() == nil {
                        params["creditCard"] = cc
                    }
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: params)
                })
            navigationController!.pushViewController(vc, animated: true)
        }
        
    }
    
    @IBAction func cashCheckPressed(_ sender: AnyObject) {
        let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func giftCardPressed(_ sender: AnyObject) {
        if !FPServer.sharedInstance.reachabilityManager.isReachable {
            FPAlertManager.showMessage("Redeeming gift cards is currently unavailable. Please try again later.", withTitle:"")
            return
        }
        let completion = { () -> Void in
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": 5])
        }
        let vc = FPRedeemGiftCardViewController.redeemGiftCardViewControllerWithDidRedeemHandler(completion)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    
    class func payNowViewController() -> FPPayNowViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPPayNowViewController") as! FPPayNowViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.balanceBtn.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = UIColor.white
        }
        
        if let customer = FPCustomer.activeCustomer(), FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) > 0 {
            var balance = FPCartView.sharedCart().sumWithTax
            if FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) < FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                balance = customer.balance
            } else if FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) >= FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                balance = 0.00
            }
            FPCartView.sharedCart().applicableBalance = balance
        }
        
        self.updateUI()
        
        navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        if FPCustomer.activeCustomer() != nil {
            giftCardBtn.isEnabled = true
        } else {
            giftCardBtn.isEnabled = false
        }
        preferredContentSize = CGSize(width: 640, height: 468)
    }
    
    func updateUI() {
        if let customer = FPCustomer.activeCustomer(), FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) > 0 {
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                clearBtn.isHidden = FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().applicableBalance) == 0
            }
            
            balanceBtn.isHidden = false
            balanceLabel.isHidden = false
            balanceLabel.text = "Current balance: $" + FPCurrencyFormatter.printableCurrency(customer.balance)
            
            balanceBtn.setTitle("Balance applied: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().applicableBalance), for: .normal)
            navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
        }
    }
    
    // MARK: - UIActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let title = actionSheet.buttonTitle(at: buttonIndex)
        if actionSheet.tag == 2 && title != "Cancel"{
            let useCardFlight = title == "Swipe Credit Card"
            self.cardAction(useCardFlight)
        }
    }
    
    func cardAction(_ useCardFlight: Bool) {
        let vc = FPCreateCreditCardViewController.createCreditCardViewControllerWithCardSelectedHandler({ creditCard, transactionToken, last4 in
            let sum = FPCartView.sharedCart().checkoutSum
            var params: Dictionary<String, AnyObject> = ["method": 1 as AnyObject, "sumPaid": sum as AnyObject]
            if let cc = creditCard {
                if FPCustomer.activeCustomer() == nil {
                    params["creditCard"] = cc
                }
            }
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: params)
            })
        vc.useCardFlightIfPossible = useCardFlight
        navigationController!.pushViewController(vc, animated: true)
    }
}
