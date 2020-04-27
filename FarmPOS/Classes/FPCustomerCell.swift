//
//  FPCustomerCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/17/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCustomerCell: UITableViewCell {
    
    var displayId = true
    var cellHeight: CGFloat = 0.0
    weak var delegate: FPCustomerCellDelegate?
    var customer: FPCustomer! {
        didSet {
            var balance = "$" + FPCurrencyFormatter.printableCurrency(customer.balance)
            if customer.farmBucks > 0.00 {
                balance = "$" + FPCurrencyFormatter.printableCurrency(customer.balance + customer.farmBucks) + " ($\(FPCurrencyFormatter.printableCurrency(customer.balance)) + $\(FPCurrencyFormatter.printableCurrency(customer.farmBucks)) Farm Bucks)"
            }
            var text = "\(customer.name)\nEmail: \(customer.email)\nPhone: \(customer.phone)\nBalance: \(balance)\nPIN: \(customer.pin)"
            var processStrs = ["Email:", "Phone:", "Balance:", "PIN:"]
            if displayId {
                text += "\nID: \(customer.id)"
                processStrs.append("ID:")
            }
            
            if let address = customer.address {
                if (address as NSString).length > 0 {
                    processStrs.append("Address:")
                    text += "\nAddress: \(address)"
                }
            }
            
            let contentAttrText = NSMutableAttributedString(string: text)
            contentAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue-Medium", size: 21.0)!, range: (contentAttrText.string as NSString).range(of: customer.name))
            
            for txt in processStrs {
                contentAttrText.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 146.0 / 255.0, green: 146.0 / 255.0, blue: 146.0 / 255.0, alpha: 1.0), range: (contentAttrText.string as NSString).range(of: txt))
            }
            
            contentLabel.attributedText = contentAttrText
            
            contentLabel.frame.size.height = contentLabel.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width - 25.0, height: CGFloat.greatestFiniteMagnitude)).height
            balanceBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
            transactionsBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                historyBtn.frame.origin.x = transactionsBtn.frame.origin.x + transactionsBtn.frame.width + 8.0;
                historyBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
                historyBtn.frame = CGRect(x: historyBtn.frame.origin.x, y: historyBtn.frame.origin.y, width: balanceBtn.frame.width + 20, height: historyBtn.frame.height)
                
                editBtn.frame.origin.x = historyBtn.frame.origin.x + historyBtn.frame.width + 8.0;
                editBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
                editBtn.frame = CGRect(x: editBtn.frame.origin.x, y: editBtn.frame.origin.y, width: historyBtn.frame.width, height: editBtn.frame.height)
            } else {
                historyBtn.frame.origin.x = contentLabel.frame.origin.x
                historyBtn.frame.origin.y = transactionsBtn.frame.origin.y + transactionsBtn.frame.size.height + 8.0
                // Static for iPhone
                historyBtn.frame = CGRect(x: historyBtn.frame.origin.x, y: historyBtn.frame.origin.y, width: 252, height: historyBtn.frame.height)
                
                editBtn.frame.origin.x = contentLabel.frame.origin.x
                editBtn.frame.origin.y = historyBtn.frame.origin.y + historyBtn.frame.size.height + 8.0
                // Static for iPhone
                editBtn.frame = CGRect(x: editBtn.frame.origin.x, y: editBtn.frame.origin.y, width: 252, height: editBtn.frame.height)
            }
            
            let lastView = contentView.lastView()!
            cellHeight = lastView.frame.size.height + lastView.frame.origin.y + 10.0
        }
    }
    
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var balanceBtn: UIButton!
    @IBOutlet var transactionsBtn: UIButton!
    @IBAction func historyPressed(_ sender: AnyObject) {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Processing"
        FPServer.sharedInstance.sendClientPurchaseHistoryForClient(self.customer, completion: { (errMsg) -> Void in
            hud?.hide(false)
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else {
                FPAlertManager.showMessage("Purchase history sent", withTitle: "Success")
            }
        })
    }
    
    @IBAction func balancePressed(_ sender: AnyObject) {
        delegate?.customerCellDidPressBalance(self)
    }
    
    @IBAction func transactionsPressed(_ sender: AnyObject) {
        delegate?.customerCellDidPressTransactions(self)
    }
    
    @IBAction func editPressed(_ sender: AnyObject) {
        delegate?.customerCellDidPressEdit(self)
    }
    
    @IBOutlet weak var historyBtn: UIButton!
    @IBOutlet weak var editBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentLabel.textColor = FPColorDarkGray
        balanceBtn.backgroundColor = UINavigationBar.appearance().barTintColor
        transactionsBtn.backgroundColor = balanceBtn.backgroundColor
        historyBtn.backgroundColor = balanceBtn.backgroundColor
        editBtn.backgroundColor = balanceBtn.backgroundColor
    }
    
    class func cellHeightForCustomer(_ customer: FPCustomer) -> CGFloat {
        let oc = Bundle.main.loadNibNamed("FPCustomerCell", owner: nil, options: nil)?[0] as! FPCustomerCell
        oc.customer = customer
        return oc.cellHeight
    }
    
}

@objc protocol FPCustomerCellDelegate {
    func customerCellDidPressBalance(_ cell: FPCustomerCell) -> Void
    func customerCellDidPressTransactions(_ cell: FPCustomerCell) -> Void
    func customerCellDidPressEdit(_ cell: FPCustomerCell) -> Void
}
