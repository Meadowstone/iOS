//
//  FPUnsyncedPurchaseCell.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 26/08/2014.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPUnsyncedPurchaseCell: UITableViewCell {
    
    var cellHeight: CGFloat = 0.0
    var tableView: UITableView!
    var purchase: FPCDPurchase! {
        didSet {
            
            let params = NSKeyedUnarchiver.unarchiveObject(with: purchase.params as Data) as! NSDictionary
            let contentAttrText = NSMutableAttributedString()
            
            var str = ""
            for (key, value) in params as! [String: AnyObject] {
                let attrText = NSMutableAttributedString(string: str + "\(key): \(value)")
                str = "\n"
                if key == "client_id" {
                    let range = (attrText.string as NSString).range(of: "client_id")
                    attrText.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: range)
                }
                contentAttrText.append(attrText)
            }
            contentLabel.frame.size.width = tableView.bounds.size.width - 25.0
            contentLabel.attributedText = contentAttrText
            contentLabel.frame.size.height = contentLabel.sizeThatFits(CGSize(width: tableView.bounds.size.width - 25.0, height: CGFloat.greatestFiniteMagnitude)).height
            cellHeight = contentLabel.frame.size.height + contentLabel.frame.origin.y + 8.0
        }
    }
    
    @IBOutlet weak var contentLabel: UILabel!

    class func cellHeightForPurchase(_ purchase: FPCDPurchase, tableView: UITableView) -> CGFloat {
        let oc = Bundle.main.loadNibNamed("FPUnsyncedPurchaseCell", owner: nil, options: nil)?[0] as! FPUnsyncedPurchaseCell
        oc.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 0.0)
        oc.tableView = tableView
        oc.purchase = purchase
        return oc.cellHeight
    }
}
