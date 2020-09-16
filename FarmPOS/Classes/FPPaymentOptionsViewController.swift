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
    
    @IBOutlet var cardflightActivityIndicator: UIActivityIndicatorView!
    
    var balancePayment = false
    var hasCards = false
    var balanceSum : Double = 0.0
    
    @IBAction func payNowPressed(_ sender: AnyObject?) {
        let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
        navigationController!.pushViewController(vc, animated: true)
        return
        // WORKAROUND
//        if let ac = FPCustomer.activeCustomer() {
//            //ZORGadd!
//            if FPUser.activeUser() != nil && FPUser.activeUser()!.farm != nil && FPUser.activeUser()!.farm!.allowCreditCardPayments {
//                if FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) <= FPCurrencyFormatter.intCurrencyRepresentation(ac.balance) {
//                    
//                    
//                } else {
//                    self.payNowBtn.setTitle("Pay With Cash/Check", for: UIControlState())
//                    self.payLaterBtn.setTitle("Pay Later", for: UIControlState())
//                }
//                return
//            }
//            if FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) <= FPCurrencyFormatter.intCurrencyRepresentation(ac.balance) {
//                payLaterBtn.setTitle("Pay With Balance", for: UIControlState())
//            }
//        }
        //        let vc = FPPayNowViewController.payNowViewController()
        //        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func payLaterPressed(_ sender: AnyObject) {
        if let ac = FPCustomer.activeCustomer() {
            //ZORGadd!
            if FPUser.activeUser() != nil && FPUser.activeUser()!.farm != nil && FPUser.activeUser()!.farm!.allowCreditCardPayments {
                if FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) <= FPCurrencyFormatter.intCurrencyRepresentation(ac.balance) {
                    
                    let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
                    navigationController!.pushViewController(vc, animated: true)
                    
                } else {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": 4])
                }
                return
            }
        }
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
        
        if (FPCustomer.activeCustomer() != nil) {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            FPServer.sharedInstance.creditCardsWithCompletion(true, completion: {[weak self] errMsg, cards, count in
                MBProgressHUD.hide(for: self?.view, animated: true)
//                if errMsg != nil {
//                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                if let count = count, errMsg == nil {
                    self?.hasCards = count > 0
                    self?.updateChoices()
                }
            })
        } else {
            updateChoices()
        }
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
        
        cardflightActivityIndicator.isHidden = true
        
        preferredContentSize = CGSize(width: 640, height: 468)
    }
    
    func updateChoices() {
        button1.setTitle("Pay with Cash", for: .normal)
        button1.tag = 1
        
        button2.setTitle("Pay with Check", for: .normal)
        button2.tag = 2
        
        button3.isHidden = false
        button4.isHidden = false
        button5.isHidden = false
        
        if let ac = FPCustomer.activeCustomer() {
            if !balancePayment {
                if FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) <= FPCurrencyFormatter.intCurrencyRepresentation(ac.balance) {
                    button3.setTitle("Pay with Balance", for: .normal)
                    button3.tag = 5
                } else {
                    button3.setTitle("Pay Later", for: .normal)
                    button3.tag = 6
                }
                button4.setTitle("Pay with Credit/Debit Card", for: .normal)
                button4.tag = 7
                button5.isHidden = true
            } else {
                button3.isHidden = true
                button4.isHidden = true
                button5.isHidden = true
            }
        } else {
            button3.isHidden = true
            button4.isHidden = true
            button5.isHidden = true
        }
    }
    
    //MARK: - Payment action
    @IBAction func buttonPressed(_ sender: AnyObject?) {
        switch sender!.tag {
        case 1:
            if !balancePayment {
                // Pay with cash
                let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
                vc.mode = 1
                navigationController!.pushViewController(vc, animated: true)
            } else {
                // Balance payment with case
                depositSumPayWithCheck(false, creditCard: false, checkNumber: nil, transactionToken: nil, last4: nil)
            }
        case 2:
            if !balancePayment {
                // Pay with check
                let vc = FPCashCheckViewController.cashCheckViewControllerShowCancel(false)
                vc.mode = 2
                navigationController!.pushViewController(vc, animated: true)
            } else {
                // Balance payment with check
                let alert = UIAlertView()
                alert.alertViewStyle = .plainTextInput
                alert.tag = 2
                alert.message = "Check number"
                alert.delegate = self
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Submit")
                alert.show()
            }
        case 5:
            // Pay With Balance
            let notificationParams: [String : Any] = [
                "method": FPPaymentMethod.balance.rawValue,
                "sumPaid": FPCartView.sharedCart().checkoutSum
            ]
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification),
                                            object: notificationParams)
        case 6:
            // Pay later
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["method": 4])
        case 7:
            // Pay with Payment Card
            let payWithPaymentCardViewController = FPPayWithPaymentCardViewController()
            
            payWithPaymentCardViewController.unableToStartPayment = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
                FPAlertManager.showMessage("Please try again later.", withTitle: "Unable to make card payments at the moment")
            }
            
            payWithPaymentCardViewController.paymentSucceeded = { [weak self] in
                self?.navigationController?.popViewController(animated: true)
                let notificationParams: [String : Any] = [
                    "method": FPPaymentMethod.paymentCard.rawValue,
                    "sumPaid": FPCartView.sharedCart().checkoutSum
                ]
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification),
                                                object: notificationParams)
            }
            
            navigationController?.pushViewController(payWithPaymentCardViewController, animated: true)
        default:
            ()
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
        NotificationCenter.default.addObserver(self, selector: #selector(FPPaymentOptionsViewController.checkCardFlightStatus), name: NSNotification.Name(rawValue: FPReaderStatusChangedNotification), object: nil)
        // Advanced logging
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "SEND CARDFLIGHT LOG", style: .plain, target: self, action: #selector(FPPaymentOptionsViewController.sendEmail(_:)))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone {
            navigationItem.title = ""
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: FPReaderStatusChangedNotification), object: nil)
        super.viewDidDisappear(animated)
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
    func depositSumPayWithCheck(_ isCheck: Bool, creditCard: Bool, checkNumber: String?, transactionToken: String?, last4: String?) {
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
                } else if creditCard {
                    if FPFarmWorker.activeWorker() == nil {
                        message = "You will receive an email receipt of your deposit."
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
        FPServer.sharedInstance.balanceDepositWithSum(self.balanceSum, isCheck: isCheck, useCreditCard: creditCard, checkNumber: checkNumber, transactionToken: transactionToken, last4: last4, completion: completion)
    }
    
    // UIAlertView delegate (probably can be removed since it's deprecated and not called anymore)
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 1 {
            // Call balance competion handler
            balanceCompletionHandler()
        } else if alertView.tag == 2 && buttonIndex == 1 {
            let text = alertView.textField(at: 0)!.text
            depositSumPayWithCheck(true, creditCard: false, checkNumber: text, transactionToken: nil, last4: nil)
        }
    }
    //MARK: - Cardflight
    @objc func checkCardFlightStatus() {
        print("reader status: \(FPCardFlightManager.sharedInstance.statusCode.hashValue)")
        if FPCardFlightManager.sharedInstance.statusCode == StatusCode.readerAttached || FPCardFlightManager.sharedInstance.statusCode == StatusCode.readerConnecting {
            cardflightActivityIndicator.isHidden = false
            if !cardflightActivityIndicator.isAnimating {
                cardflightActivityIndicator.startAnimating()
            }
            button3.setTitle("Connecting to terminal...", for: .normal)
        } else {
            cardflightActivityIndicator.stopAnimating()
            cardflightActivityIndicator.isHidden = true
            updateChoices()
        }
    }
}

extension FPPaymentOptionsViewController : MFMailComposeViewControllerDelegate {
    //MARK: mail view controller
    @IBAction func sendEmail(_ sender: UIButton) {
        //Check to see the device can send email.
        if( MFMailComposeViewController.canSendMail() ) {
            print("Can send email.")
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            // Set the subject and message of the email
            mailComposer.setSubject("CardFlight log")
            //mailComposer.setMessageBody("This is what they sound like.", isHTML: false)
            
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
        
            let path = (paths as NSString).appendingPathComponent("cardFlightLog.txt")
            
            //            if let fileData = data {
            //                let content = NSString(data: fileData, encoding:NSUTF8StringEncoding) as! String
            //            }
            
            mailComposer.setToRecipients(["yaroslav@mojosells.com"])
            
            do {
                let logData = try Data(contentsOf: URL(fileURLWithPath: path))
                mailComposer.addAttachmentData(logData, mimeType: "text/plain", fileName: "cardFlightLog")
                self.present(mailComposer, animated: true, completion: nil)
            } catch {}
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
