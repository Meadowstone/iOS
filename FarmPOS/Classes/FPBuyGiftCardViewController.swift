//
//  FPBuyGiftCardViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPBuyGiftCardViewController: FPRotationViewController, UITextFieldDelegate {
    
    var domains = [".edu", ".net", ".com", ".org", ".gov", ".coop"]
    var domain = ".com"
    var email = ""
    var choiceOverlayView: FPChoiceOverlayView?
    var giftCard: FPGiftCard!
    var cardBoughtHandler: (() -> Void)!
    
    @IBOutlet var emailNameTextField: UITextField!
    @IBOutlet var emailLabel: UILabel!
    @IBOutlet var websiteNameTextField: UITextField!
    @IBOutlet var domainBtn: UIButton!
    
    @IBAction func emailEditingChanged(_ sender: AnyObject) {
        updateEmail()
    }

    @IBAction func domainPressed(_ sender: UIButton) {
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
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        // before removing the old credit card code, there was an option to buy gift card by using credit card here 
    }
    
    class func buyGiftCardViewControllerWithGiftCard(_ giftCard: FPGiftCard, cardBoughtHandler:@escaping () -> Void) -> FPBuyGiftCardViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPBuyGiftCardViewController") as! FPBuyGiftCardViewController
        vc.giftCard = giftCard
        vc.cardBoughtHandler = cardBoughtHandler
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Gift Card - $" + NumberFormatter().string(from: NSNumber(value: self.giftCard.sum))!
        
        let em = FPCustomer.activeCustomer()!.email
        emailNameTextField.text = (em as NSString).substring(to: (em as NSString).range(of: "@").location)
        let ws = (em as NSString).substring(from: (em as NSString).range(of: "@").location + 1)
        websiteNameTextField.text = (ws as NSString).substring(to: (ws as NSString).range(of: ".", options: .backwards).location)
        domain = (ws as NSString).substring(from: (ws as NSString).range(of: ".", options: .backwards).location)
        domainBtn.setTitle(domain, for: .normal)
        updateEmail()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailNameTextField.becomeFirstResponder()
    }
    
    func updateEmail() {
        var hasSuffix = false
        for domain in domains {
            if (websiteNameTextField.text! as NSString).hasSuffix(domain) {
                hasSuffix = true
                break
            }
        }
        let webText = hasSuffix ? websiteNameTextField.text : websiteNameTextField.text! + domain
        email = emailNameTextField.text! + "@" + webText!
        emailLabel.text = "EMAIL YOU'VE ENTERED: " + email
    }
    
    func overlayDisplayRectForView(_ view: UIView) -> CGRect {
        return CGRect(x: view.frame.origin.x - 8.0 - 110.0, y: view.frame.origin.y + (view.frame.size.height / 2.0) - 100.0, width: 110.0, height: 200.0)
    }
    
    // TextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailNameTextField {
            websiteNameTextField.becomeFirstResponder()
        } else if textField === websiteNameTextField {
            domainPressed(domainBtn)
        }
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        choiceOverlayView?.removeFromSuperview()
    }
}
