//
//  FPCustomerLoginViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/1/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCustomerLoginViewController: FPRotationViewController, UIPopoverControllerDelegate, UITextFieldDelegate {
    
    var popover: UIPopoverController?
    
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var pinTextField: UITextField!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var cardflightLoginButton: UIButton!
    
    @IBAction func loginPressed(_ sender: AnyObject?) {
        
        var phone: String = phoneTextField.text!
        if (phone as NSString).length == 7 {
            phone = FPUser.activeUser()!.defaultStateCode + phone
        } else if (phone as NSString).length != 10 {
            FPAlertManager.showMessage("Invalid phone", withTitle: "Error")
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Logging in"
        let completion = {[weak self] (errMsg: String?, customer: FPCustomer?) -> Void in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self?.customerAuthenticated(customer!)
            }
        }
        
        FPServer.sharedInstance.customerAuthenticateWithPhone(phone, pin: pinTextField.text!, completion: completion)
    }
    
    @IBAction func cardflightLoginPressed(_ sender: AnyObject?) {
        if !FPUser.activeUser()!.farm!.canUseCreditCard {
            FPAlertManager.showMessage("This farm is not configured to use credit cards.", withTitle: "Error")
            return
        }
        // Wait for card swipe
        switch (FPCardFlightManager.sharedInstance.statusCode!) {
        case .readerAttached, .readerConnecting, .readerDisconnected, .generic, .waitingForSwipe:
            _ = ""
        default:
            FPCardFlightManager.sharedInstance.waitForSwipe()
        }
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
    
    @IBAction func guestPressed(_ sender: AnyObject) {
        self.customerAuthenticated(nil)
    }
    
    class func customerLoginViewController() -> FPCustomerLoginViewController {
        return FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPCustomerLoginViewController") as! FPCustomerLoginViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        FPCardFlightManager.sharedInstance.cancelSwipe()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        navigationItem.title = "Customer Login"
        
//        pinTextField.text = "11"
//        phoneTextField.text = "6032222224"
        
        // Setup observers
        NotificationCenter.default.addObserver(self, selector: #selector(FPCustomerLoginViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPCustomerLoginViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // @Cardflight notifications
        NotificationCenter.default.addObserver(self, selector: #selector(FPCustomerLoginViewController.updateReaderStatus), name: Notification.Name(rawValue: FPReaderStatusChangedNotification), object: nil)
        
        for textField in [phoneTextField, pinTextField] {
            if let placeholder = textField?.placeholder {
                textField?.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            }
        }
        
        // Initialize instance
        _ = FPCardFlightManager.sharedInstance
    }
    
    func customerAuthenticated(_ customer: FPCustomer?) {
        FPCustomer.setActiveCustomer(customer)
        let vc = FPProductsAndCartViewController.productsAndCartViewController()
        let nc = UINavigationController(rootViewController: vc)
        FPAppDelegate.instance().window!.rootViewController = nc
    }
    
    // TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === phoneTextField {
            pinTextField.becomeFirstResponder()
        } else {
            self.loginPressed(nil)
        }
        return false
    }
    
    @objc func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string as NSString).length == 0 {
            return true
        }
        let resultText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let length = (resultText as NSString).length
        if textField === phoneTextField {
            return (string as NSString).rangeOfCharacter(from: CharacterSet(charactersIn: "1234567890")).length > 0 && length <= 10
        } else if textField === pinTextField {
            return length <= 2
        }
        return true
    }
    
    
    // Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if var kbRect = (note.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            kbRect = FPAppDelegate.instance().window!.convert(kbRect, to: view)
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    @objc func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
    // Popover delegate
    func popoverControllerShouldDismissPopover(_ popoverController: UIPopoverController) -> Bool {
        return false
    }
    
    //MARK: @Cardflight-related
    @objc func updateReaderStatus() {
        var status = FPCardFlightManager.sharedInstance.status
        
        switch (FPCardFlightManager.sharedInstance.statusCode!) {
        case .swipeTimedOut :
            status = "LOGIN WITH CARD"
            FPAlertManager.showMessage(FPCardFlightManager.sharedInstance.status, withTitle: "Warning")
        case .readerConnected :
            status = "LOGIN WITH CARD"
        case .readerDisconnected:
            status = "LOGIN WITH CARD"
            FPAlertManager.showMessage(FPCardFlightManager.sharedInstance.status, withTitle: "Warning")
        case .recognizedCard:
            let token = FPCardFlightManager.sharedInstance.getCardToken()
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
            hud?.labelText = "Logging in"
            let completion = {[weak self] (errMsg: String?, customer: FPCustomer?) -> Void in
                hud?.hide(false)
                if errMsg != nil {
                    // Reset card
                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    self?.cardflightLoginButton.setTitle("LOGIN WITH CARD", for: .normal)
                    FPCardFlightManager.sharedInstance.cardFlightCard = nil
                } else {
                    self?.customerAuthenticated(customer!)
                }
            }
            FPServer.sharedInstance.cardflightLogin(token, completion: completion)
            
        default:
            break
        }
        
        self.cardflightLoginButton.setTitle(status, for: .normal)
    }
}
