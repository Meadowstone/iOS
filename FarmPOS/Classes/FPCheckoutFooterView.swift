//
//  FPCheckoutFooterView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/20/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPCheckoutFooterView: UIView {
    
    @IBOutlet var sumLabel: UILabel!
    @IBOutlet var currentBalanceLabel: UILabel!
    @IBOutlet var farmAddressTextView: UITextView!
    @IBOutlet var customerAddressTextView: UITextView!
    
    class func checkoutFooterView() -> FPCheckoutFooterView {
        let nibName = UIDevice.current.userInterfaceIdiom == .pad ? "FPCheckoutFooterView-iPad" : "FPCheckoutFooterView"
        let view = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?[0] as! FPCheckoutFooterView
        view.sumLabel.text = "$" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().sumWithTax)
        
        if let farm = FPUser.activeUser()?.farm {
            let farmAddressAttrText = NSMutableAttributedString(string: "Farm:\n\(farm.name)\n\(farm.address), \(farm.city), \(farm.state), \(farm.zipCode)")
            farmAddressAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 21.0)!, NSForegroundColorAttributeName: FPColorGreen], range: (farmAddressAttrText.string as NSString).range(of: "Farm:"))
            farmAddressAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 20.0)!, NSForegroundColorAttributeName: UIColor.darkText], range: (farmAddressAttrText.string as NSString).range(of: "\(farm.name)"))
            farmAddressAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 20.0)!, NSForegroundColorAttributeName: UIColor.darkText], range: (farmAddressAttrText.string as NSString).range(of: "\(farm.address), \(farm.city), \(farm.state), \(farm.zipCode)"))
            view.farmAddressTextView.attributedText = farmAddressAttrText
            view.farmAddressTextView.textAlignment = NSTextAlignment.center
        }
        
        var customerAddressAttrText: NSMutableAttributedString
        
        if let ac = FPCustomer.activeCustomer() {
            let contentAttrText = NSMutableAttributedString()
            if ac.balance != 0.00 || ac.farmBucks > 0.00 {
                var balanceText = "$"
                if ac.farmBucks > 0.00 {
                    balanceText += FPCurrencyFormatter.printableCurrency(ac.balance + ac.farmBucks)
                    balanceText += " ($\(FPCurrencyFormatter.printableCurrency(ac.balance)) + $\(FPCurrencyFormatter.printableCurrency(ac.farmBucks)) Farm Bucks)"
                } else {
                    balanceText += FPCurrencyFormatter.printableCurrency(ac.balance)
                }
                let balanceAttrText = NSMutableAttributedString(string: "Your current balance: \(balanceText)")
                let range = (balanceAttrText.string as NSString).range(of: balanceText)
                balanceAttrText.addAttributes([NSForegroundColorAttributeName: FPColorGreen, NSFontAttributeName: UIFont(name: "HelveticaNeue", size: view.currentBalanceLabel.font.pointSize)!], range: range)
                contentAttrText.append(balanceAttrText)
            }
            
            if FPCartView.sharedCart().sumWithTax > 0.00 {
                var balanceAfterText = "$"
                if ac.farmBucks > 0.00 {
                    var sum = FPCartView.sharedCart().sumWithTax
                    let fb = FPCartView.sharedCart().applicableFarmBucks
                    let farmBucks = max(ac.farmBucks - fb, 0.00)
                    sum = max(sum - fb, 0.00)
                    let balance = ac.balance - sum
                    balanceAfterText += FPCurrencyFormatter.printableCurrency(balance + farmBucks)
                    balanceAfterText += " ($\(FPCurrencyFormatter.printableCurrency(balance)) + $\(FPCurrencyFormatter.printableCurrency(farmBucks)) Farm Bucks)"
                } else {
                    let balanceAfterCheckout = ac.balance - FPCartView.sharedCart().sumWithTax
                    balanceAfterText += FPCurrencyFormatter.printableCurrency(balanceAfterCheckout)
                }
                let balanceAfterAttrText = NSMutableAttributedString(string: "\nWith this purchase, your new account balance is: \(balanceAfterText)")
                let range = (balanceAfterAttrText.string as NSString).range(of: balanceAfterText)
                balanceAfterAttrText.addAttributes([NSForegroundColorAttributeName: FPColorGreen, NSFontAttributeName: UIFont(name: "HelveticaNeue", size: view.currentBalanceLabel.font.pointSize)!], range: range)
                contentAttrText.append(balanceAfterAttrText)
            }
            
            view.currentBalanceLabel.attributedText = contentAttrText
            view.currentBalanceLabel.frame.size.height = view.currentBalanceLabel.sizeThatFits(CGSize(width: view.currentBalanceLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
            
            var customerString = "Receipt For: \n\(ac.name)"
            if ac.address != nil && (ac.address! as NSString).length > 0 {
                customerString += "\n\(ac.address!)"
            }
            var address = [String]()
            if ac.city != nil && (ac.city! as NSString).length > 0 {
                address.append(ac.city!)
            }
            if ac.state != nil && (ac.state! as NSString).length > 0 {
                address.append(ac.state!)
            }
            if ac.zip != nil && (ac.zip! as NSString).length > 0 {
                address.append(ac.zip!)
            }
            
            let a = (address as NSArray).componentsJoined(by: ", ")
            if a.count > 0 {
                customerString += "\n\(a)"
            }
            
            customerAddressAttrText = NSMutableAttributedString(string: customerString)
            customerAddressAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue-Light", size: 20.0)!, range: NSMakeRange(0, (customerAddressAttrText.string as NSString).length))
            customerAddressAttrText.addAttributes([NSForegroundColorAttributeName: FPColorGreen, NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 21.0)!], range: (customerAddressAttrText.string as NSString).range(of: "Receipt For:"))
            customerAddressAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue", size: 20.0)!, range: (customerAddressAttrText.string as NSString).range(of: ac.name))
        } else {
            view.currentBalanceLabel.isHidden = true
            customerAddressAttrText = NSMutableAttributedString(string: "Receipt For: Guest")
            customerAddressAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue-Light", size: 20.0)!, range: NSMakeRange(0, (customerAddressAttrText.string as NSString).length))
            customerAddressAttrText.addAttributes([NSForegroundColorAttributeName: FPColorGreen, NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 21.0)!], range: (customerAddressAttrText.string as NSString).range(of: "Receipt For:"))
            customerAddressAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue", size: 20.0)!, range: (customerAddressAttrText.string as NSString).range(of: "Guest"))
        }
        view.customerAddressTextView.attributedText = customerAddressAttrText
        view.customerAddressTextView.textAlignment = .center
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            view.customerAddressTextView.frame.origin.y = view.currentBalanceLabel.frame.size.height + view.currentBalanceLabel.frame.origin.y + 8.0
            view.farmAddressTextView.frame.origin.y = view.customerAddressTextView.frame.size.height + view.customerAddressTextView.frame.origin.y + 16.0
        }
        
        return view
    }
    
}
