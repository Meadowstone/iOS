//
//  FPCustomerCreateViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCustomerCreateViewController: FPRotationViewController, UITextFieldDelegate {
    
    var domains = [".edu", ".net", ".com", ".org", ".gov", ".coop"]
    var domain = ".com"
    var numbers = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    var email: String?
    var choiceOverlayView: FPChoiceOverlayView?
    var completion: ((FPCustomer?) -> Void)!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var emailNameTextField: UITextField!
    @IBOutlet var websiteNameTextField: UITextField!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var domainBtn: UIButton!
    @IBOutlet var leftPinBtn: UIButton!
    @IBOutlet var rightPinBtn: UIButton!
    @IBOutlet var pinLabel: UILabel!
    @IBOutlet var cancelBtn: UIButton!
    @IBOutlet var createAccountBtn: UIButton!
    
    @IBAction func domainPressed(_ sender: UIView) {
        view.endEditing(true)
        choiceOverlayView?.removeFromSuperview()
        choiceOverlayView = FPChoiceOverlayView.choiceOverlayViewWithFrame(overlayDisplayRectForView(sender), dataSource: domains, font: nil, completion: {[weak self] choice in
            self!.domainBtn.setTitle(choice, for: .normal)
            self!.domain = choice
            self!.updateEmail()
            self!.choiceOverlayView!.removeFromSuperview()
        })
        choiceOverlayView!.showInView(self.view)
    }
    
    @IBAction func pinPressed(_ sender: UIButton) {
        view.endEditing(true)
        choiceOverlayView?.removeFromSuperview()
        choiceOverlayView = FPChoiceOverlayView.choiceOverlayViewWithFrame(overlayDisplayRectForView(sender), dataSource: numbers, font: nil, completion: {[weak self] choice in
            sender.setTitle(choice, for: .normal)
            self!.pinLabel.text = self!.leftPinBtn.title(for: .normal)! + self!.rightPinBtn.title(for: .normal)!
            if sender === self!.leftPinBtn {
                self!.pinPressed(self!.rightPinBtn)
            } else {
                self!.choiceOverlayView!.removeFromSuperview()
            }
        })
        choiceOverlayView!.showInView(self.view)
    }
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        completion(nil)
    }
    
    @IBAction func createAccountPressed(_ sender: AnyObject?) {
        var errMsg: String?
        
        if (nameTextField.text! as NSString).length == 0 {
            errMsg = "Enter name"
        }
        
        var phone: String = phoneTextField.text!
        if (phone as NSString).length == 7 {
            phone = FPUser.activeUser()!.defaultStateCode + phone
        } else if (phone as NSString).length != 10 {
            errMsg = "Invalid phone"
        }
        
        var pin = ""
        if UIDevice.current.userInterfaceIdiom == .phone {
            email = emailTextField.text!
            pin = pinTextField.text!
        } else {
            pin = self.leftPinBtn.title(for: .normal)! + self.rightPinBtn.title(for: .normal)!
        }
        
        if email == nil || (email! as NSString).length == 0 {
            errMsg = "Enter a valid email"
        }
        
        if (pin as NSString).length != 2 {
            errMsg = "PIN code must consist of 2 digits"
        }
        
        if errMsg != nil {
            FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            return
        }
        
        self.view.endEditing(true)
        
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Creating customer"
        let completion = { [weak self] (errMsg: String?, customer: FPCustomer?) -> Void in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self!.completion(customer)
            }
        }
        FPServer.sharedInstance.customerCreateWithName(nameTextField.text!, email: email!, pin: pin, phone: phone, phoneHome: nil, state: nil, city: nil, zip: nil, address: nil, completion: completion)
    }
    
    @IBAction func emailEditingChanged(_ sender: AnyObject) {
        self.updateEmail()
    }
    
    
    class func customerCreateViewControllerWithCompletion(_ completion: @escaping (FPCustomer?) -> Void) -> FPCustomerCreateViewController {
        let vc = FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPCustomerCreateViewController") as! FPCustomerCreateViewController
        vc.completion = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)
        }
        
        navigationItem.title = "New Customer"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(FPCustomerCreateViewController.createAccountPressed(_:)))
        
        for textField in [nameTextField, phoneTextField, emailNameTextField, websiteNameTextField, emailTextField, pinTextField] {
            if textField == nil {
                continue
            }
            if let placeholder = textField!.placeholder {
                textField!.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            }
        }
    }
    
    func updateEmail() {
        var hasSuffix = false
        for domain in domains {
            if (websiteNameTextField.text! as NSString).hasSuffix(domain) {
                hasSuffix = true
                break
            }
        }
        let webText = hasSuffix ? websiteNameTextField.text! : websiteNameTextField.text! + domain
        email = emailNameTextField.text! + "@" + webText
        emailLabel.text = "ENTER EMAIL: " + email!
    }
    
    func overlayDisplayRectForView(_ view: UIView) -> CGRect {
        return CGRect(x: view.frame.origin.x, y: view.frame.origin.y + (view.frame.size.height / 2.0) - 100.0, width: view.frame.size.width, height: 200.0)
    }
    
    // TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if textField === nameTextField {
                phoneTextField.becomeFirstResponder()
            } else if textField === phoneTextField {
                emailNameTextField.becomeFirstResponder()
            } else if textField === emailNameTextField {
                websiteNameTextField.becomeFirstResponder()
            } else if textField === websiteNameTextField {
                domainPressed(domainBtn)
            }
        } else {
            if textField === nameTextField {
                phoneTextField.becomeFirstResponder()
            } else if textField === phoneTextField {
                emailTextField.becomeFirstResponder()
            } else if textField === emailTextField {
                pinTextField.becomeFirstResponder()
            } else {
                createAccountPressed(nil)
            }
        }
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string as NSString).length == 0 {
            return true
        }
        let resultText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let length = (resultText as NSString).length
        if textField === phoneTextField {
            return (string as NSString).rangeOfCharacter(from: NSCharacterSet(charactersIn: "1234567890") as CharacterSet).length > 0 && length <= 10
        } else if textField === pinTextField {
            return length <= 2
        }
        return true
    }
    
}
