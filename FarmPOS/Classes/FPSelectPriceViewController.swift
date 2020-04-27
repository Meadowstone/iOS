//
//  FPSelectPriceViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 10/06/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPSelectPriceViewController: FPRotationViewController {

    @IBOutlet weak var selectPriceBtn: UIButton!
    @IBOutlet weak var numPadPlaceholderView: UIView!
    
    @IBOutlet weak var priceTextField: UITextField!
    @IBAction func selectPricePressed(_ sender: AnyObject) {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        
        var text = ""
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            text = numPadView.textField.text!
        } else {
            text = priceTextField.text!
        }
        
        if let price = nf.number(from: text) as? Double {
            priceSelectedHandler(price)
        } else {
            FPAlertManager.showMessage("Enter valid price", withTitle: "Error")
        }
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        let tfText = sender.text!
        if (tfText as NSString).length > 0 {
            let text = (tfText as NSString).substring(from: (tfText as NSString).length - 1)
            sender.text = (tfText as NSString).substring(to: (tfText as NSString).length - 1)
            let t = FPInputValidator.preprocessCurrencyText(text, relativeTo: tfText)
            if FPInputValidator.shouldAddString(t, toString: tfText, maxInputCount: Int.max, isDecimal: true) {
                sender.text = tfText + t
            }
        }
    }
    
    var popover: UIPopoverController!
    var priceSelectedHandler: ((_ price: Double) -> Void)!
    var numPadView: FPNumPadView!
    
    class func selectPriceViewControllerWithPriceSelectedHandler(_ priceSelectedHandler: @escaping (Double) -> Void) -> FPSelectPriceViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPSelectPriceViewController") as! FPSelectPriceViewController
        vc.priceSelectedHandler = priceSelectedHandler
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Product price"
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            numPadView = FPNumPadView.numPadViewForPaymentWithEditingHandler(nil)
            numPadView.textField.placeholder = "Enter Price"
            numPadPlaceholderView.addSubview(numPadView)
            self.popover.contentSize = CGSize(width: self.preferredContentSize.width, height: self.preferredContentSize.height + self.navigationController!.navigationBar.frame.size.height)
        } else {
            self.priceTextField.becomeFirstResponder()
        }
    }

}
