//
//  FFPCheckoutViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/18/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCheckoutViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIPopoverControllerDelegate {
    
    var popover: UIPopoverController?
    var tableView: UITableView!
    var checkoutItems =  FPCartView.sharedCart().checkoutItems()
    var paymentAlertView: UIAlertView!
    var paymentTimer: Timer?
    
    var performPaymentHandler: (() -> Void)!
    
    class func checkoutViewController() -> FPCheckoutViewController {
        let vc = FPCheckoutViewController()
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table view
        tableView = UITableView(frame: view.bounds)
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            
            // Cell
            tableView.register(UINib(nibName: "FPProductCheckoutCell-iPad", bundle: nil), forCellReuseIdentifier: "FPProductCheckoutCell")
            
            // Title view
            let imgView = UIImageView(image: UIImage(named: "ipad_navbar_logo"))
            imgView.frame = CGRect(x: 0.0, y: 0.0, width: imgView.image!.size.width, height: imgView.image!.size.height)
            navigationItem.titleView = imgView
            
            // Left buttons
            let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 64.0))
            leftView.isUserInteractionEnabled = true
            leftView.backgroundColor = UIColor.clear
            
            let cancelBtn = UIButton(type: .custom)
            cancelBtn.addTarget(self, action: #selector(FPCheckoutViewController.cancelPressed), for: .touchUpInside)
            cancelBtn.setTitle("Cancel", for: .normal)
            cancelBtn.setTitleColor(UIColor.lightGray, for: .highlighted)
            cancelBtn.sizeToFit()
            cancelBtn.frame.size.height = leftView.frame.size.height
            leftView.addSubview(cancelBtn)
            
            leftView.frame = CGRect(x: 0.0, y: 0.0, width: cancelBtn.frame.size.width + cancelBtn.frame.origin.x, height: 64.0)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftView)
        } else {
            
            // Cell
            tableView.register(UINib(nibName: "FPProductCheckoutCell", bundle: nil), forCellReuseIdentifier: "FPProductCheckoutCell")
            tableView.separatorStyle = .singleLine
            tableView.separatorColor = UINavigationBar.appearance().barTintColor
            
            navigationItem.title = "Check Out"
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPCheckoutViewController.cancelPressed))
        }
        
        // Right button
        if FPCustomer.activeCustomer() != nil {
            if FPUser.activeUser()!.farm!.allowCustomerBalancePayments {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Manage balance", style: .plain, target: self, action: #selector(FPCheckoutViewController.manageBalancePressed))
            }
        }
        
        // Header view
        let headerView = FPCheckoutHeaderView.checkoutHeaderView()
        headerView.buyBtn.addTarget(self, action: #selector(FPCheckoutViewController.buyPressed), for: .touchUpInside)
        var hasDiscounts = false
        for ci in checkoutItems {
            if let p = ci as? FPCheckoutProduct {
                if p.product.hasDiscount || p.isCSA {
                    hasDiscounts = true
                    break
                }
            }
        }
        headerView.hasDiscounts = hasDiscounts
        tableView.tableHeaderView = headerView
        
        // Footer
        updateFooter()
    }
    
    func showPaymentAlertWithMessage(_ message: String, andTitle title: String) {
        paymentAlertView = UIAlertView()
        paymentAlertView.delegate = self
        paymentAlertView.title = title
        paymentAlertView.message = message
        paymentAlertView.addButton(withTitle: "Dismiss")
        paymentAlertView.show()
        
        paymentTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(FPCheckoutViewController.paymentProcessed), userInfo: nil, repeats: false)
    }
    
    @objc func paymentProcessed() {
        paymentTimer?.invalidate()
        paymentAlertView?.dismiss(withClickedButtonIndex: 0, animated: false)
        
        // Perform cleanup
        FPOrder.setActiveOrder(nil)
        FPTransaction.setActiveTransaction(nil)
        FPCustomer.setActiveCustomer(nil)
        FPCartView.sharedCart().resetCart()
        
        if FPFarmWorker.activeWorker() != nil {
            navigationController!.popViewController(animated: true)
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPUserLoginStatusChanged), object: ["status": FPLoginStatus.loggedOut.rawValue, "user": FPFarmWorker()])
        }
        
    }
    
    @objc func dismiss() {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            popover!.dismiss(animated: false)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func manageBalancePressed() {
        let completion = { [weak self] () -> Void in
            self!.tableView.reloadData()
            self!.updateFooter()
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                self!.popover!.dismiss(animated: false)
            } else {
                self!.dismiss(animated: true, completion: nil)
            }
        }
        
        let vc = FPManageBalanceViewController.manageBalanceViewControllerWithCompletion(completion)
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPCheckoutViewController.dismiss as (FPCheckoutViewController) -> () -> ()))
        let nc = UINavigationController(rootViewController: vc)
        nc.navigationBar.isTranslucent = false
        nc.navigationBar.barStyle = .black
        nc.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            displayPopoverInViewController(nc)
        } else {
            present(nc, animated: true, completion: nil)
        }
    }
    
    func updateFooter() {
        tableView.tableFooterView = FPCheckoutFooterView.checkoutFooterView()
    }
    
    @objc func cancelPressed() {
        let alert = UIAlertView()
        alert.delegate = self
        alert.title = "Cancel transaction"
        alert.message = "Are you sure?"
        alert.addButton(withTitle: "Don't cancel")
        alert.addButton(withTitle: "Yes, cancel")
        alert.show()
    }
    
    @objc func buyPressed() {
        NotificationCenter.default.addObserver(self, selector: #selector(FPCheckoutViewController.paymentMethodSelected(_:)), name: NSNotification.Name(rawValue: FPPaymentMethodSelectedNotification), object: nil)
        
        if FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: ["covered": true, "method": 4])
        } else {
            let vc = FPPaymentOptionsViewController.paymentOptionsViewController()
            let nc = UINavigationController(rootViewController: vc)
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                displayPopoverInViewController(nc)
            } else {
                present(nc, animated: true, completion: nil)
            }
        }
    }
    
    func displayPopoverInViewController(_ vc: UIViewController) {
        let centerRect = CGRect(x: view.frame.size.width / 2, y: view.frame.size.height / 2, width: 1, height: 1)
        popover = UIPopoverController(contentViewController: vc)
        popover!.delegate = self
        popover?.present(from: centerRect, in: view, permittedArrowDirections: .init(rawValue: 0), animated: false)
    }
    
    // UITableView delegate & data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            return 45.0
        } else {
            return FPProductCheckoutCell.cellHeightForCheckoutItem(self.checkoutItems[indexPath.row])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return checkoutItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPProductCheckoutCell") as! FPProductCheckoutCell
        cell.checkoutItem = checkoutItems[indexPath.row]
        return cell
    }
    
    // UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView === paymentAlertView {
            paymentProcessed()
            return
        }
        if alertView.tag == 1 {
            performPaymentHandler()
            return
        }
        if buttonIndex == 1 {
            navigationController!.popViewController(animated: true)
        }
    }
    
    // Popover delegate
    func popoverControllerShouldDismissPopover(_ popoverController: UIPopoverController) -> Bool {
        return false
    }
    
    // Observers
    @objc func paymentMethodSelected(_ note: Notification) {
        
        let noteInfo = (note.object as! NSDictionary)
        print("method selected \(noteInfo)")
        
        let change = noteInfo["change"] as? Double
        let covered = noteInfo["covered"] as? Bool
        let last4 = noteInfo["last_4"] as? String
        let transactionToken = noteInfo["transaction_token"] as? String
        let creditCard = noteInfo["creditCard"] as? FPCreditCard
        let checkNumber = noteInfo["checkNumber"] as? String
        let sumPaid = noteInfo["sumPaid"] as? Double
        
        var priorBalance: Double!
        var priorFarmBucks: Double!
        var priorText = ""
        if let ac = FPCustomer.activeCustomer() {
            priorBalance = ac.balance
            priorFarmBucks = ac.farmBucks
            if priorFarmBucks > 0.00 {
                priorText = "$" + FPCurrencyFormatter.printableCurrency(priorBalance + priorFarmBucks) + " ($\(FPCurrencyFormatter.printableCurrency(priorBalance)) + $\(FPCurrencyFormatter.printableCurrency(priorFarmBucks)) Farm Bucks)"
            } else {
                priorText = "$" + FPCurrencyFormatter.printableCurrency(priorBalance)
            }
        }
        
        performPaymentHandler = {
            [weak self] in
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                self?.popover?.dismiss(animated: false)
            } else {
                self!.dismiss(animated: true, completion: nil)
            }
            self?.updateFooter()
            NotificationCenter.default.removeObserver(self!, name: NSNotification.Name(rawValue: FPPaymentMethodSelectedNotification), object: nil)
            let method = FPPaymentMethod(rawValue: noteInfo["method"] as! Int)!
            if method == FPPaymentMethod.cancelled || method == FPPaymentMethod.giftCard {
                FPCartView.sharedCart().applicableBalance = 0.0
                return
            }
            
            
            var sum = sumPaid
            if FPFarmWorker.activeWorker() != nil && FPCustomer.activeCustomer() == nil {
                sum = FPCartView.sharedCart().checkoutSum
            }
//                if let c = change {
//                    if sum != nil {
//                        sum! -= c
//                    }
//                }
//            }
            
            var hud: MBProgressHUD!
            let completion = { (errMsg: String?, didSaveOffline: Bool) -> Void in
                hud.hide(false)
                
                if errMsg != nil {
                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    return
                }
                
                var title = "Purchase recorded"
                var message = ""
                let covd = covered != nil && covered!
                var paid = false
                if let ao = FPOrder.activeOrder() {
                    paid = ao.isPaid
                }
                if covd || paid {
                    title = "Success!"
                    message = "Purchase has been successfully recorded."
                } else if method == FPPaymentMethod.payLater {
                    var newBalanceText = "$" + FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.balance)
                    if FPCustomer.activeCustomer()!.farmBucks > 0.00 {
                        newBalanceText = "$" + FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.balance + FPCustomer.activeCustomer()!.farmBucks) + " ($\(FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.balance)) + $\(FPCurrencyFormatter.printableCurrency(FPCustomer.activeCustomer()!.farmBucks)))"
                    }
                    // Positive balance left - simplify message
                    if FPCustomer.activeCustomer()!.balance > 0 {
                        message = "Purchase Completed! Thank You"
                    } else {
                        message = "Your purchase has been recorded on your account. You will receive an email receipt for this transaction. Prior to this purchase, your balance was \(priorText). Your new balance is \(newBalanceText). You will receive an email statement on the first of the month with all of your monthly purchases listed. Full payment for this outstanding balance is due within fifteen (15) days. You can pay at that time either by check or credit card. Thanks so much for visiting our farmstand."
                    }
                } else if method == FPPaymentMethod.cash || method == FPPaymentMethod.check {
                    if FPFarmWorker.activeWorker() != nil {
                        if change != nil && change! > 0 {
                            message = "Transaction was a success. Please give the customer back the following amount of change: $\(FPCurrencyFormatter.printableCurrency(change!))"
                        } else{
                            message = "Purchase successfully recorded."
                        }
                    } else if FPCustomer.activeCustomer() == nil {
                        if change != nil && change! > 0 {
                            message = "Transaction was a success. Please take the following amount of change: $\(FPCurrencyFormatter.printableCurrency(change!))"
                        } else {
                            title = "Thanks for your purchase!"
                            message = "Please drop your check or cash into the container labeled \"Cash/Check Box.\""
                        }
                    } else {
                        title = "Thanks for your purchase!"
                        message = "Please drop your check or cash into the container labeled \"Cash/Check Box.\"\nYou will receive an email receipt of your purchase."
                    }
                } else if method == FPPaymentMethod.creditCard {
                    title = "Success!"
                    message = "Purchase successfully recorded!"
                }
                if didSaveOffline {
                    title += " - Offline purchase"
                }
                self?.showPaymentAlertWithMessage(message, andTitle: title)
            }
            
            if let ac = FPCustomer.activeCustomer() {
                for cp in FPCartView.sharedCart().cartProducts {
                    for pd in ac.productDescriptors {
                        if cp.product.id == pd.productId {
                            pd.csas = cp.product.csas
                        }
                    }
                }
                FPDataAccessLayer.sharedInstance.saveCustomer(ac)
            }
            
            hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud.removeFromSuperViewOnHide = true
            hud.labelText = "Finalizing transaction"
            FPServer.sharedInstance.paymentProcessWithSum(sum, method: method, checkNumber: checkNumber, creditCard: creditCard, transactionToken : transactionToken, last4: last4, completion: completion)
        }
        
        let covd = covered != nil && covered!
        var paid = false
        if let ao = FPOrder.activeOrder() {
            paid = ao.isPaid
        }
        if covd || paid {
            let alert = UIAlertView()
            alert.delegate = self
            alert.title = ""
            if paid {
                alert.message = "This order is paid for online and does not require a payment."
            } else {
                alert.message = "This purchase is fully covered by Customer's balance."
            }
            alert.tag = 1
            alert.addButton(withTitle: "OK")
            alert.show()
        } else {
            performPaymentHandler()
        }
    }
}
