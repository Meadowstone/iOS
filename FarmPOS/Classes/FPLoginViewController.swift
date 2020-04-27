//
//  FPLoginViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/26/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPLoginViewController: FPRotationViewController, UITextFieldDelegate {
    
    @IBOutlet var scrollView : UIScrollView!
    @IBOutlet var farmIDTextField : UITextField!
    @IBOutlet var emailTextField : UITextField!
    @IBOutlet var passwordTextField : UITextField!
    
    @IBAction func loginPressed(_ sender : UIButton?) {
        if (emailTextField.text! as NSString).length == 0 || (passwordTextField.text! as NSString).length == 0 {
            return
        }
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Logging in"
        let completion = { (errMsg: String?) -> Void in
            hud?.hide(false)
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            }
        }
        FPServer.sharedInstance.loginWithFarmID(farmIDTextField.text!, email: emailTextField.text!, password: passwordTextField.text!, completion: completion)
    }
    
    
    class func loginViewController() -> FPLoginViewController {
        return FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPLoginViewController") as! FPLoginViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.statusBarStyle = .default
        
        // Setup observers
        NotificationCenter.default.addObserver(self, selector: #selector(FPLoginViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPLoginViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        for textField in [emailTextField, passwordTextField] {
            textField?.attributedPlaceholder = NSAttributedString(string : (textField?.placeholder!)!, attributes: [NSForegroundColorAttributeName: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
        }
    }
    
    // TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === farmIDTextField) {
            emailTextField.becomeFirstResponder()
        } else if (textField === emailTextField) {
            passwordTextField.becomeFirstResponder()
        } else {
            loginPressed(nil)
        }
        return false
    }
    
    // Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillChangeFrame(_ note: Notification) {
        if var kbRect = (note.userInfo![UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            kbRect = FPAppDelegate.instance().window!.convert(kbRect, to: view)
            let insets = UIEdgeInsetsMake(0, 0, kbRect.size.height, 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
}
