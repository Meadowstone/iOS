//
//  FPNumPadView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/10/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPNumPadView : UIView {
    
    @IBOutlet var sumButtons: [UIButton]!
    var isForPounds = false
    var maxInputCount = 0
    var editingChangedHandler: ((String) -> Void)?
    var shouldShowDot: Bool = true {
    didSet {
        dotBtn.isHidden = !shouldShowDot
        if let su = sumButtons {
            for btn in su {
                btn.isHidden = !shouldShowDot
            }
        }
        
        if shouldShowDot {
            zeroBtn.frame = CGRect(x: dotBtn.frame.origin.x + dotBtn.frame.size.width + 8.0,
                y: zeroBtn.frame.origin.y,
                width: 228.0,
                height: zeroBtn.frame.size.height)
        } else {
            zeroBtn.frame = CGRect(x: dotBtn.frame.origin.x,
                y: zeroBtn.frame.origin.y,
                width: 346.0,
                height: zeroBtn.frame.size.height)
        }
    }
    }
    
    @IBOutlet var textField: UITextField!
    @IBOutlet var zeroBtn: UIButton!
    @IBOutlet var dotBtn: UIButton!
    
    @IBAction func clearPressed(_ sender: AnyObject) {
        if (textField.text! as NSString).length > 0 {
            textField.text = (textField.text! as NSString).substring(to: (textField.text! as NSString).length - 1)
        }
        editingChangedHandler?(textField.text!)
    }
    
    @IBAction func numberPressed(_ sender: UIButton) {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        
        var textToAdd = ""
        var shouldAddAsQuantity = false
        if sender.title(for: .normal)!.hasPrefix("+$") {
            shouldAddAsQuantity = true
            textToAdd = (sender.title(for: .normal)! as NSString).substring(from: 2)
        } else if sender.title(for: .normal)!.hasPrefix("+") {
            shouldAddAsQuantity = true
            textToAdd = (sender.title(for: .normal)! as NSString).substring(from: 1)
        } else {
            textToAdd = FPInputValidator.preprocessCurrencyText(sender.title(for: .normal)!, relativeTo: textField.text!)
        }
        
        if shouldAddAsQuantity {
            var cn = 0.0
            if (textField.text! as NSString).length > 0 {
                cn = nf.number(from: textField.text!) as! Double
            }
            let tn = nf.number(from: textToAdd) as! Double
            textField.text = nf.string(from: NSNumber(value: cn + tn))!
        } else {
            if shouldAddString(textToAdd) {
                //@warning added check for isDecimal (gift card redeem)
                if !self.shouldShowDot {
                    textToAdd = (textToAdd as NSString).replacingOccurrences(of: ".", with: "")
                }
                textField.text = textField.text! + textToAdd
            }
        }
        
        editingChangedHandler?(textField.text!)
    }
    
    
    class func numPadViewForPounds(_ forPounds: Bool, maxInputCount: Int = Int.max, shouldShowDot: Bool = true, editingHanlder:((String) -> Void)?) -> FPNumPadView {
        let views = Bundle.main.loadNibNamed("FPNumPadView", owner: nil, options: nil)
        let npv = views?.filter({ return ($0 as AnyObject).tag == (forPounds ? 2 : 1) })[0] as! FPNumPadView
        npv.editingChangedHandler = editingHanlder
        npv.isForPounds = forPounds
        npv.maxInputCount = maxInputCount
        npv.shouldShowDot = shouldShowDot
        npv.backgroundColor = UIColor.clear
        npv.textField.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
        return npv
    }
    
    class func numPadViewForPaymentWithEditingHandler(_ editingHandler:((String) -> Void)?) -> FPNumPadView {
        let views = Bundle.main.loadNibNamed("FPNumPadView", owner: nil, options: nil)
        let npv = views?.filter({ return ($0 as AnyObject).tag == 3 })[0] as! FPNumPadView
        npv.editingChangedHandler = editingHandler
        npv.maxInputCount = Int.max
        npv.shouldShowDot = true
        npv.backgroundColor = UIColor.clear
        npv.textField.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
        return npv
    }
    
    func shouldAddString(_ string: String) -> Bool {
        return FPInputValidator.shouldAddString(string, toString: textField.text!, maxInputCount: maxInputCount, isDecimal: shouldShowDot)
    }
    
}
