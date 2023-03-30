//
//  FPAccountSetupViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/3/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPAccountSetupViewController: FPRotationViewController {
    
    var completion: ((FPCustomer?) -> Void)!
    var customer: FPCustomer?
    
    @IBOutlet var contentLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var cancelBtn: UIButton!
    @IBOutlet var nextBtn: UIButton!
    @IBOutlet var closeBtn: UIButton!
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        completion(nil)
    }
    
    @IBAction func nextPressed(_ sender: AnyObject) {
        let completion = { [weak self] (customer: FPCustomer?) -> Void in
            self!.customer = customer
            self!.navigationController!.popViewController(animated: true)
        }
        let vc = FPCustomerCreateViewController.customerCreateViewControllerWithCompletion(completion)
        vc.preferredContentSize = preferredContentSize
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func closePressed(_ sender: AnyObject) {
        completion(customer)
    }
    
    
    class func accountSetupViewControllerWithCompletion(_ completion:@escaping (_ customer: FPCustomer?) -> Void) -> FPAccountSetupViewController {
        let vc = FPStoryboardManager.loginStoryboard().instantiateViewController(withIdentifier: "FPAccountSetupViewController") as! FPAccountSetupViewController
        vc.completion = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Farmstand Account Setup"
        
        navigationController!.navigationBar.barStyle = .black
        navigationController!.navigationBar.isTranslucent = false
        
        preferredContentSize = CGSize(width: 640, height: 468)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        contentLabel.text = ""
        contentLabel.attributedText = nil
        
        if let c = customer {
            navigationItem.hidesBackButton = true
            cancelBtn.isHidden = true
            nextBtn.isHidden = true
            closeBtn.isHidden = false
            
            let attrText = NSMutableAttributedString(string: "Your account has been set up. You have been emailed your account information. Your information is:\n\nName: \(c.name)\nPhone: \(c.phone)\nE-mail: \(c.email)\nPIN code: \(c.pin)\n\nWe will email your purchase receipts and your monthly statement to \(c.email)\n\nPlease let us know of any comments and concerns. " + FPUser.activeUser()!.farm!.name)
            
            attrText.addAttribute(.font, value: UIFont(name: "HelveticaNeue-Light", size:20.0)!, range: NSMakeRange(0, (attrText.string as NSString).length))
            
            let attributes: [NSAttributedString.Key : Any] = [
                .font: UIFont(name: "HelveticaNeue", size: 20)!,
                .foregroundColor: FPColorGreen
            ]
            for text in [c.name, c.phone, c.email, c.pin] {
                attrText.addAttributes(attributes, range: (attrText.string as NSString).range(of: text))
            }
            
            let range = (attrText.string as NSString).range(of: "to \(c.email)")
            attrText.addAttribute(.font, value: UIFont(name: "HelveticaNeue", size: 20)!, range: NSMakeRange(range.location + 3, range.length - 3))
            
            contentLabel.attributedText = attrText
        } else {
            contentLabel.text = """
            Meadowstone Farm uses an account system for customers to purchase farmstand items. 
            After the short process of setting up an account the customer can receive a $10 credit by pre-purchasing $100 of Farm Bucks. 
            Once an account is created customers login using a phone number and 2 digit pin code and then can select items from the Farmstand and "put it on the account”. A receipt of purchases will be sent to the email provided during the account setup. Thank you for supporting Meadowstone Farm!

            To set up an account press the Next button below.
            """
            contentLabel.font = UIFont(name: "HelveticaNeue-Light", size: 21)
        }
    }
    
}
