//
//  FPFarmWorkerLoginViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/30/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPFarmWorkerLoginViewController: FPRotationViewController, UITextFieldDelegate {
    
    var emails: NSArray!
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var retailLocationTextField: UITextField!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBAction func loginPressed(_ sender: AnyObject?) {
        if retailLocationTextField.text!.count == 0 {
            FPAlertManager.showMessage("Select location", withTitle: "Error")
            return
        }
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Logging in"
        let completion = {(errMsg: String?) -> Void in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                FPProduct.resetAllProducts()
            }
        }
        
        FPServer.sharedInstance.farmWorkerAuthenticateWithEmail(emailTextField.text!, password: passwordTextField.text!, completion: completion)
    }
    
    
    class func farmWorkerLoginViewController() -> FPFarmWorkerLoginViewController {
        return FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPFarmWorkerLoginViewController") as! FPFarmWorkerLoginViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Farm worker login"
        
        // Setup observers
        NotificationCenter.default.addObserver(self, selector: #selector(FPFarmWorkerLoginViewController.keyboardWillChangeFrame(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPFarmWorkerLoginViewController.keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        // Locations
        var dataSource = ["No Location"]
        if let rls = FPRetailLocation.allRetailLocationsNames() {
            if rls.count > 0 {
                dataSource += rls
            }
        }
        
        if let defaultLocationName = FPRetailLocation.defaultLocationName() {
            retailLocationTextField.text = defaultLocationName
        }
        
        retailLocationTextField.inputView = FPChoiceInputView.choiceInputViewWithDataSource(dataSource,
            completion: { [weak self] (choice: String) -> Void in
                self!.retailLocationTextField.text = choice
                self!.retailLocationTextField.resignFirstResponder()
                FPRetailLocation.makeDefault(choice)
            })
        
        for textField in [emailTextField, passwordTextField, retailLocationTextField] {
            if let placeholder = textField!.placeholder {
                textField!.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [NSForegroundColorAttributeName: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadFarmWorkerEmails()
    }
    
    func loadFarmWorkerEmails() {
        activityIndicator.startAnimating()
        FPServer.sharedInstance.farmWorkerEmailsCompletion({ [weak self] errMsg, emails in
            if self == nil {
                return
            }
            self!.activityIndicator.stopAnimating()
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self!.emails = emails
                self!.emailTextField.inputView = FPChoiceInputView.choiceInputViewWithDataSource(self!.emails as! Array<String>!,
                    completion: { [weak self] (choice: String) -> Void in
                        self!.emailTextField.text = choice
                        self!.passwordTextField.becomeFirstResponder()
                    })
                self!.emailTextField.becomeFirstResponder()
            }
            })
    }
    
    // TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField === emailTextField) {
            passwordTextField.becomeFirstResponder()
        }
        else if (textField == passwordTextField) {
            retailLocationTextField.becomeFirstResponder()
        }
        else {
            self.loginPressed(nil)
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
