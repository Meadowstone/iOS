//
//  FPAuthOptionsViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/27/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPAuthOptionsViewController: FPRotationViewController {
    
    var popover: UIPopoverController?
    var timer: Timer!
    
    @IBOutlet weak var syncActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var syncBtn: UIButton!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var markImageView: UIImageView!
    
    @IBAction func customerPressed(_ sender: UIButton) {
        let vc = FPCustomerLoginViewController.customerLoginViewController()
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func guestPressed(_ sender: AnyObject) {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Entering POS..."
        
        let completion = { [weak self] (errorMessage: String?, productDescriptors: [FPProductDescriptor]?) -> Void in
            hud?.hide(false)
            if let errorMessage = errorMessage {
                FPAlertManager.showMessage(errorMessage, withTitle: "Error")
                return
            }
            self?.customerAuthenticated(nil)
            FPProduct.addDiscounts(using: productDescriptors ?? [])
        }
        
        FPServer.sharedInstance.guestCheckout(completion: completion)
    }
    
    @IBAction func createAccountPressed(_ sender: AnyObject?) {
        self.view.endEditing(true)
        
        let completion = { [weak self] (customer: FPCustomer?) -> Void in
            self!.popover!.dismiss(animated: false)
            if let c = customer {
                self!.customerAuthenticated(c)
            }
        }
        let vc = FPAccountSetupViewController.accountSetupViewControllerWithCompletion(completion)
        let nc = UINavigationController(rootViewController: vc)
        let centerRect = CGRect(x: view.frame.size.width / 2, y: view.frame.size.height / 2, width: 1, height: 1)
        popover = UIPopoverController(contentViewController: nc)
        popover!.delegate = self
        popover?.present(from: centerRect, in: view, permittedArrowDirections: UIPopoverArrowDirection(rawValue: 0), animated: false)
    }
    
    @IBAction func farmWorkerPressed(_ sender: UIButton) {
        let vc = FPFarmWorkerLoginViewController.farmWorkerLoginViewController()
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func syncPressed(_ sender: AnyObject) {
        if !FPServer.sharedInstance.reachabilityManager.isReachable {
            return
        }
        FPSyncManager.sharedInstance.syncWithCompletion(nil)
        updateUI()
    }
    
    func customerAuthenticated(_ customer: FPCustomer?) {
        FPCustomer.setActiveCustomer(customer)
        let vc = FPProductsAndCartViewController.productsAndCartViewController()
        let nc = UINavigationController(rootViewController: vc)
        FPAppDelegate.instance().window!.rootViewController = nc
    }
    
    class func authOptionsViewController() -> FPAuthOptionsViewController {
        return FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPAuthOptionsViewController") as! FPAuthOptionsViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        navigationItem.title = "Welcome!"
        navigationController!.navigationBar.isTranslucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Log out", style: .plain, target: self, action: #selector(FPAuthOptionsViewController.logout))
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPAuthOptionsViewController.updateUI), name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
        
        if (FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() || FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() || FPServer.sharedInstance.hasUpdates) {
            syncPressed(syncBtn)
        }
        
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.isUserInteractionEnabled = false
        timer = Timer.scheduledTimer(timeInterval: 0.16, target: self, selector: #selector(FPAuthOptionsViewController.timerOff), userInfo: nil, repeats: false)
        
        FPServer.sharedInstance.syncAPNsToken()
    }
    
    @objc func updateUI() {
        if FPServer.sharedInstance.syncingDatabase || FPServer.sharedInstance.syncing {
            syncActivityIndicator.startAnimating()
            syncBtn.setTitle("Synchronizing", for: .normal)
            syncBtn.isUserInteractionEnabled = false
        } else {
            syncActivityIndicator.stopAnimating()
            syncBtn.setTitle("Synchronize", for: .normal)
            syncBtn.isUserInteractionEnabled = true
        }
        versionLabel.text = "Last database sync date: "
        if let sd = UserDefaults.standard.object(forKey: FPDatabaseSyncDateUserDefaultsKey) as? Date {
            let df = DateFormatter()
            df.dateFormat = "MM/dd/yyyy hh:mm a"
            versionLabel.text = versionLabel.text! + df.string(from: sd)
        } else {
            versionLabel.text = versionLabel.text! + "Never"
        }
        markImageView.isHidden = !(FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() || FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() || FPServer.sharedInstance.hasUpdates)
    }
    
    @objc func timerOff() {
        view.isUserInteractionEnabled = true
        timer.invalidate()
        
        let syncDate = UserDefaults.standard.object(forKey: FPDatabaseSyncDateUserDefaultsKey) as? NSDate
        if syncDate == nil {
            syncPressed(syncBtn)
        }
    }
    
    @objc func logout() {
        let alert = UIAlertController(title: "Are you sure you want to log out?", message: nil, preferredStyle: .alert)
        let noAction = UIAlertAction(title: "No", style: .cancel)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            let obj = ["status": FPLoginStatus.loggedOut.rawValue, "user": FPUser.activeUser()!] as [String : Any]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue:  FPUserLoginStatusChanged), object: obj, userInfo: nil)            
        }
        alert.addAction(noAction)
        alert.addAction(yesAction)
        present(alert, animated: true)
    }
    
}

extension FPAuthOptionsViewController: UIPopoverControllerDelegate {
    
    func popoverControllerShouldDismissPopover(_ popoverController: UIPopoverController) -> Bool {
        return false
    }
}
