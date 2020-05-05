//
//  FPPasswordInputViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/30/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit

class FPPasswordInputViewController: FPRotationViewController, UITextFieldDelegate {
    
    var password = ""
    var message = ""
    var completionHandler: ((Bool) -> Void)!
    
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var passwordTextField: UITextField!
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        completionHandler(true)
    }
    
    @IBAction func okPressed(_ sender: AnyObject?) {
        if passwordTextField.text == password {
            completionHandler(false)
        } else {
            FPAlertManager.showMessage("Password incorrect!", withTitle: "Error!")
        }
    }
    
    
    class func passwordInputViewControllerForPassword(_ password: String, message: String, completion:@escaping (_ cancelled: Bool) -> Void) -> FPPasswordInputViewController {
        let vc = FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPPasswordInputViewController") as! FPPasswordInputViewController
        vc.password = password
        vc.message = message
        vc.completionHandler = completion
        if UIDevice.current.userInterfaceIdiom == .pad {
            vc.preferredContentSize = CGSize(width: 470, height: 320)
        }
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageLabel.text = message
        
        if UIDevice.current.userInterfaceIdiom != .pad {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .plain, target: self, action: #selector(FPPasswordInputViewController.okPressed(_:)))
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPPasswordInputViewController.cancelPressed(_:)))
        }
        
        passwordTextField.attributedPlaceholder = NSAttributedString(string : passwordTextField.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        passwordTextField.becomeFirstResponder()
    }
    
    // TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.okPressed(nil)
        return false
    }
    
}
