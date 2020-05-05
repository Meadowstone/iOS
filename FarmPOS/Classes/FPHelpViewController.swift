//
//  FPHelpViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPHelpViewController: FPRotationViewController {
    
    var numPadView: FPNumPadView!
    var cancelBlock: (() -> Void)!
    
    @IBOutlet var numPadViewContainerView: UIView!
    
    @IBAction func callFarmerPressed(_ sender: AnyObject) {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Calling"
        FPServer.sharedInstance.helpWithPhone("", completion: {errMsg in
            hud?.hide(false)
            var message = "The farmer has been notified and will assist you shortly"
            var title = "Success"
            if errMsg != nil {
                message = errMsg!
                title = "Error"
            }
            FPAlertManager.showMessage(message, withTitle:title)
        })
    }
    
    @IBAction func callMePressed(_ sender: AnyObject) {
        var phone = numPadView.textField.text!
        
        if (phone as NSString).length == 7 {
            phone = FPUser.activeUser()!.defaultStateCode + phone
        } else if (phone as NSString).length != 10 {
            FPAlertManager.showMessage("Enter valid phone", withTitle: "Error")
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Calling"
        FPServer.sharedInstance.helpWithPhone(phone, completion: {errMsg in
            hud?.hide(false)
            var message = "The farmer has been notified and will assist you shortly"
            var title = "Success"
            if errMsg != nil {
                message = errMsg!
                title = "Error"
            }
            FPAlertManager.showMessage(message, withTitle:title)
        })
    }
    
    
    class func helpNavigationViewControllerWithCancelBlock(_ cancelBlock: @escaping () -> Void) -> UINavigationController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPHelpViewController") as! FPHelpViewController
        vc.cancelBlock = cancelBlock
        let nc = UINavigationController(rootViewController: vc)
        return nc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController!.navigationBar.barStyle = .black;
        navigationController!.navigationBar.isTranslucent = false;
        
        navigationItem.title = "Help"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPHelpViewController.cancelPressed))
        
        numPadView = FPNumPadView.numPadViewForPounds(false, maxInputCount: 10, shouldShowDot: false, editingHanlder: nil)
        numPadView.textField.placeholder = "Phone number"
        numPadView.textField.attributedPlaceholder = NSAttributedString(string : numPadView.textField.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
        numPadViewContainerView.addSubview(numPadView)
        
        let lastView = view.lastView()!
        preferredContentSize = CGSize(width: popoverWidth, height: lastView.frame.size.height + lastView.frame.origin.y + 20.0)
    }
    
    @objc func cancelPressed() {
        cancelBlock()
    }
    
}
