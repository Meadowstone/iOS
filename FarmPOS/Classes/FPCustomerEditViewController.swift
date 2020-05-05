//
//  FPCustomerEditViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 13/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCustomerEditViewController: FPRotationViewController, UITextFieldDelegate {
    
    var customer: FPCustomer!
    var completion: ((_ customer: FPCustomer?, _ cancelled: Bool) -> Void)!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func customerEditViewControllerForCustomer(_ customer: FPCustomer, completion:@escaping (_ customer: FPCustomer?, _ cancelled: Bool) -> Void) -> FPCustomerEditViewController {
        let vc = UIStoryboard(name: "ProductsAndCart-iPad", bundle: nil).instantiateViewController(withIdentifier: "FPCustomerEditViewController") as! FPCustomerEditViewController
        vc.customer = customer
        vc.completion = completion
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationController?.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
        
        self.navigationItem.title = "Edit Customer"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPCustomerEditViewController.cancelPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(FPCustomerEditViewController.savePressed))
        
        self.nameTextField.text = self.customer.name
        self.emailTextField.text = self.customer.email
        self.phoneTextField.text = self.customer.phone
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPCustomerEditViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPCustomerEditViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func cancelPressed() {
        self.completion(nil, true)
    }
    
    @objc func savePressed() {
        if nameTextField.text!.count == 0 || emailTextField.text!.count == 0 || phoneTextField.text!.count == 0 {
            FPAlertManager.showMessage("Please fill in all the fields.", withTitle: "Error")
            return
        }
        
        self.view.endEditing(true)
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Saving..."
        FPServer.sharedInstance.customerEdit(customer: self.customer, self.nameTextField.text!, email: self.emailTextField.text!, phone: self.phoneTextField.text!, pin: self.customer.pin) { (errMsg, customer) -> Void in
            hud?.hide(false)
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else {
                self.completion(customer, false)
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameTextField {
            emailTextField.becomeFirstResponder()
        } else if textField === emailTextField {
            phoneTextField.becomeFirstResponder()
        } else if textField === phoneTextField {
            self.savePressed()
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 {
            return true
        }
        let resultText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let length = resultText.count
        if textField === phoneTextField {
            return (string as NSString).rangeOfCharacter(from: CharacterSet(charactersIn: "1234567890")).length > 0 && length <= 10
        }
        return true
    }
    
    // MARK: - Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if var kbRect = (note.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            kbRect = FPAppDelegate.instance().window!.convert(kbRect, to: view)
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    @objc func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }

}
