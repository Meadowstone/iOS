//
//  FPProductCell.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import SDWebImage

class FPProductCell: UITableViewCell {
    
    var inventory = false
    var cellHeight: CGFloat = 76.0
    var product: FPProduct! {
        didSet {
            imgView.sd_setImage(with: product.imageURL, placeholderImage: UIImage(named: "category_placeholder"), options: [.refreshCached, .retryFailed])
            let contentAttrText = NSMutableAttributedString(string: product.name)
            
            var color = FPColorGreen
            var onSaleText = "Yes"
            if !product.onSaleNow {
                onSaleText = "No"
                color = FPColorRed
            }
            let onSaleAttrText = NSMutableAttributedString(string: "\nOn sale now: " + onSaleText, attributes: [.font: UIFont(name: "HelveticaNeue", size: 15.0)!])
            onSaleAttrText.addAttribute(.foregroundColor, value: color, range: (onSaleAttrText.string as NSString).range(of: onSaleText))
            contentAttrText.append(onSaleAttrText)
            
            if let d = product.availableFrom {
                let df = DateFormatter()
                df.dateFormat = "MMM yyyy"
                contentAttrText.append(NSAttributedString(string: "\nAvailable from: " + df.string(from: d as Date), attributes: [.font: UIFont(name: "HelveticaNeue", size: 15.0)!]))
            }
            
            if inventory {
                var statusText = "Enabled"
                var statusColor = FPColorGreen
                if !product.trackInventory {
                    statusText = "Disabled"
                    statusColor = FPColorRed
                }
                let statusAttrText = NSMutableAttributedString(string: "\nInventory Status: " + statusText, attributes: [.font: UIFont(name: "HelveticaNeue", size: 15.0)!])
                statusAttrText.addAttribute(.foregroundColor, value: statusColor, range: (statusAttrText.string as NSString).range(of: statusText))
                contentAttrText.append(statusAttrText)
            }
            
            contentLabel.attributedText = contentAttrText
            contentLabel.frame.size.height = max(contentLabel.sizeThatFits(CGSize(width: contentLabel.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height, imgView.bounds.size.height)
            cellHeight = contentLabel.frame.origin.y + contentLabel.frame.size.height + 5.0
        }
    }

    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var contentLabel: UILabel!

    
    class func cellHeightForProduct(_ p: FPProduct, inventory: Bool, inTableView tableView: UITableView) -> CGFloat {
        let oc = Bundle.main.loadNibNamed("FPProductCell", owner: nil, options: nil)?[0] as! FPProductCell
        oc.frame.size = CGSize(width: tableView.bounds.size.width, height: 0)
        oc.inventory = inventory
        oc.product = p
        return oc.cellHeight
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.layer.cornerRadius = imgView.frame.size.height / 2
        imgView.layer.borderColor = UIColor(red: 160.0 / 255.0, green: 160.0 / 255.0, blue: 160.0 / 255.0, alpha: 1.0).cgColor
        imgView.layer.borderWidth = 1.0
    }

}
