//
//  FPSyncManager.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import MBProgressHUD

class FPSyncManager: NSObject {
    
    var syncmanagerCpl: (() -> Void)?
  
    class var sharedInstance: FPSyncManager {
        struct Static {
            static let instance = FPSyncManager()
        }
        return Static.instance
    }
    
    func syncWithCompletion(_ cpl: (() -> Void)?) {
        syncmanagerCpl = cpl
        self.syncCustomers()
    }
    
    func syncCustomers() {
        var hud: MBProgressHUD!
        let willSync = FPServer.sharedInstance.syncCustomersIfNeededCompletion { [weak self] errMsg in
            hud.hide(false)
            if errMsg != nil {
                self?.syncmanagerCpl?()
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self?.syncPayments()
            }
        }
        if !willSync {
            self.syncPayments()
        } else {
            hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud.removeFromSuperViewOnHide = true
            hud.labelText = "Syncing customers."
        }
    }
    
    func syncPayments() {
        var hud: MBProgressHUD!
        let completion = { [weak self] (errMsg: String?) -> Void in
            self?.syncmanagerCpl?()
            hud.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            }
        }
        let progress = { (p: Double) -> Void in
            hud.labelText = "Syncing database."
            if !p.isNaN {
                hud.detailsLabelText = "\(Int(p * 100.0))% completed."
                if p >= 1.0 && !hud.detailsLabelText.hasSuffix(" Saving to disk.") {
                    hud.detailsLabelText = hud.detailsLabelText + " Saving to disk."
                }
            }
        }
        let willSync = FPServer.sharedInstance.syncPaymentsIfNeededCompletion(completion, progress: progress)
        if willSync {
            hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud.removeFromSuperViewOnHide = true
            hud.labelText = "Syncing payments."
        } else {
            self.syncDatabase()
        }
    }
    
    func syncDatabase() {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Syncing database."
        hud?.detailsLabelText = ""
        let completion = { [weak self] (errMsg: String?) -> Void in
            self?.syncmanagerCpl?()
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            }
        }
        let progress = { (p: Double) -> Void in
            if !p.isNaN {
                hud?.detailsLabelText = "\(Int(p * 100.0))% completed."
                print("\(Int(p * 100.0))% completed.")
                if let hud = hud {
                    if p >= 1.0 && !hud.detailsLabelText.hasSuffix(" Saving to disk.") {
                        hud.detailsLabelText = hud.detailsLabelText + " Saving to disk."
                    }
                }
            }
        }
        FPServer.sharedInstance.syncWorkersCustomersProductsMeasurementsWithProgress(progress, completion: completion)
    }
    
}
