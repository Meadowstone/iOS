//
//  FPTransactionCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/17/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPTransactionCell: UITableViewCell {
    
    var delegate: FPTransactionCellDelegate?
    var shouldHideVoidBtn: Bool = true
    var transaction: FPTransaction!
    var cellHeight: CGFloat = 0.0
    var df: DateFormatter?

    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var voidBtn: UIButton!
    @IBOutlet weak var receiptBtn: UIButton!
    
    @IBAction func voidPressed(_ sender: AnyObject) {
        delegate?.transactionCellDidPressVoid(self)
    }
    
    @IBAction func receiptPressed(_ sender: AnyObject) {
        delegate?.transactionCellDidPressReceipt(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        voidBtn.backgroundColor = FPColorRed
        receiptBtn.backgroundColor = UINavigationBar.appearance().barTintColor
    }
    
    func setTransaction(_ t: FPTransaction, hideVoidBtn: Bool) {
        self.shouldHideVoidBtn = hideVoidBtn
        self.transaction = t
        
        if df == nil {
            df = DateFormatter()
            df!.dateFormat = "dd MMM yyyy hh:mm a"
            df!.timeZone = TimeZone.autoupdatingCurrent
        }
        
        // Name - Date
        let dateText = df!.string(from: transaction.paymentDate as Date)
        let contentAttrText = NSMutableAttributedString(string: "\(transaction.customer.name) - \(dateText)", attributes: [NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 19.0)!])
        contentAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue-Light", size: 19.0)!, range: (contentAttrText.string as NSString).range(of: dateText))
      
        // Retail location
        if let rl = transaction.retailLocation {
          let rlAttrText = NSMutableAttributedString(string: "\nRetail location: \(rl.name)")
          rlAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 19.0)!, NSForegroundColorAttributeName: FPColorGreen], range:  (rlAttrText.string as NSString).range(of: transaction.retailLocation.name))
          contentAttrText.append(rlAttrText)
        }
        
        // Sum
        let sumText = "$" + FPCurrencyFormatter.printableCurrency(transaction.sum)
        let sumAttrText = NSMutableAttributedString(string: "\nSum: \(sumText)")
        sumAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 19.0)!, NSForegroundColorAttributeName: FPColorGreen], range: (sumAttrText.string as NSString).range(of: sumText))
        contentAttrText.append(sumAttrText)
        
        // Payment type
        let paymentTypeTxt = transaction.paymentType.toString()
        contentAttrText.append(NSAttributedString(string: "\nPayment type: \(paymentTypeTxt)"))
        contentAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 19.0)!, NSForegroundColorAttributeName: UIColor(red: 108.0 / 255.0, green: 140.0 / 255.0, blue: 83.0 / 255.0, alpha: 1.0)], range: (contentAttrText.string as NSString).range(of: paymentTypeTxt))

        if let last4 = transaction.last4 {
            if last4.count > 0 {
                contentAttrText.append(NSAttributedString(string: "\nLast 4 card digits: \(last4)"))
                contentAttrText.addAttributes([NSFontAttributeName: UIFont(name: "HelveticaNeue-Bold", size: 19.0)!, NSForegroundColorAttributeName: UIColor(red: 108.0 / 255.0, green: 140.0 / 255.0, blue: 83.0 / 255.0, alpha: 1.0)], range: (contentAttrText.string as NSString).range(of: last4))
            }
        }
        
        contentLabel.attributedText = contentAttrText
        
        contentLabel.frame.size.height = contentLabel.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width - 25.0, height: CGFloat.greatestFiniteMagnitude)).height
        voidBtn.isHidden = shouldHideVoidBtn
        if !voidBtn.isHidden {
            voidBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
        }
        
        receiptBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
        
        if transaction.voided {
            voidBtn.isEnabled = false
            voidBtn.setTitle("Voided", for: .normal)
        } else {
            voidBtn.isEnabled = true
            voidBtn.setTitle("Void transaction", for: .normal)
        }
        
        let lastView = contentView.lastView()!
        cellHeight = lastView.frame.origin.y + lastView.frame.size.height + 8.0
    }
    
    class func cellHeightForTransaction(_ t: FPTransaction, hideVoidBtn: Bool) -> CGFloat {
        let cell = Bundle.main.loadNibNamed("FPTransactionCell", owner: nil, options: nil)?[0] as! FPTransactionCell
        cell.setTransaction(t, hideVoidBtn: hideVoidBtn)
        return cell.cellHeight
    }
    
}

@objc protocol FPTransactionCellDelegate {
    func transactionCellDidPressVoid(_ cell: FPTransactionCell) -> Void
    func transactionCellDidPressReceipt(_ cell: FPTransactionCell) -> Void
}
