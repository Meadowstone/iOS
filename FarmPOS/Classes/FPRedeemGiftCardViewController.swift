//
//  FPRedeemGiftCardViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/13/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPRedeemGiftCardViewController: FPRotationViewController, UITextFieldDelegate {
    
    var cardRedeemedHandler: (() -> Void)!
    var numPadView: FPNumPadView!
    
    @IBOutlet var numPadPlaceholderView: UIView!
    @IBOutlet weak var textField: UITextField!
    
    @IBAction func redeemPressed(_ sender: AnyObject) {
        var text = ""
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            text = numPadView.textField.text!
        } else {
            text = textField.text!
        }
        if (text as NSString).length != 8 {
            FPAlertManager.showMessage("Please enter a valid gift card code", withTitle: "Error")
            return
        }
        redeemGiftCardWithCode(text)
    }
    
    @IBAction func scanPressed(_ sender: AnyObject) {
        let completion = { [weak self] code in
            self!.redeemGiftCardWithCode(code)
        }
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        let vc = FPScanQRCodeViewController.scanQRCodeViewControllerForQRCodes(true, completion: completion)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    
    class func redeemGiftCardViewControllerWithDidRedeemHandler(_ handler: @escaping () -> Void) -> FPRedeemGiftCardViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPRedeemGiftCardViewController") as! FPRedeemGiftCardViewController
        vc.cardRedeemedHandler = handler
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Redeem Gift Card"
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            numPadView = FPNumPadView.numPadViewForPounds(false, maxInputCount: 8, shouldShowDot: false, editingHanlder: nil)
            numPadView.textField.placeholder = "Enter Gift Card Code"
            numPadPlaceholderView.addSubview(numPadView)
            numPadView.textField.attributedPlaceholder = NSAttributedString(string : numPadView.textField.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            
            preferredContentSize = CGSize(width: 640, height: 468)
        } else {
            textField.becomeFirstResponder()
            textField.attributedPlaceholder = NSAttributedString(string : textField.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
        }
    }
    
    func redeemGiftCardWithCode(_ code: String) {
        var hud: MBProgressHUD!
        let completion = { [weak self] (errMsg: String?, balance: Double?, cardSum: Double?) -> Void in
            hud.hide(false)
            if errMsg != nil {
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    self!.numPadView.textField.text = ""
                } else {
                    self!.textField.text = ""
                }
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                let nf = NumberFormatter()
                nf.locale = Locale(identifier: "en_US")
                FPAlertManager.showMessage("You have successfully redeemed $\(nf.string(from: NSNumber(value: cardSum!))!) gift card. Your current balance is: $\(FPCurrencyFormatter.printableCurrency(balance!))", withTitle: "Success")
                self!.cardRedeemedHandler()
            }
        }
        hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud.removeFromSuperViewOnHide = true
        hud.labelText = "Redeeming Gift Card"
        FPServer.sharedInstance.giftCardRedeemWithCode(code, completion:completion)
    }
    
    // MARK: - UITextField delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (string as NSString).length == 0 {
            return true
        }
        
        let cs = CharacterSet(charactersIn: "0123456789")
        if (string as NSString).rangeOfCharacter(from: cs).length == 0 || ((textField.text! + string) as NSString).length > 8 {
            return false
        }
        
        return true
    }
    
}
