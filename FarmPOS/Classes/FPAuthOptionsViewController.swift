//
//  FPAuthOptionsViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/27/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

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
        
        /*
         FPServer.sharedInstance.createCardflightToken("", forClientId: "302") { (errMsg) -> Void in
         
         }
         */
        //FPServer.sharedInstance.cardflightLogin("test_302", completion: { (errMsg) -> Void in
        //})
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
        let activeUser = FPUser.activeUser()!
        let vc = FPPasswordInputViewController.passwordInputViewControllerForPassword(activeUser.password, message: "Please enter Farm Owner password to log out", completion: { [weak self] (cancelled: Bool) -> Void in
            if cancelled {
                self!.popover!.dismiss(animated: true)
            }
            else {
                let obj = ["status": FPLoginStatus.loggedOut.rawValue, "user": FPUser.activeUser()!] as [String : Any]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue:  FPUserLoginStatusChanged), object: obj, userInfo: nil)
            }
        })
        let centerRect = CGRect(x: view.frame.size.width / 2, y: view.frame.size.height / 2, width: 1, height: 1)
        popover = UIPopoverController(contentViewController: vc)
        popover?.present(from: centerRect, in: view, permittedArrowDirections: UIPopoverArrowDirection(rawValue: 0), animated: false)
    }
    
}
