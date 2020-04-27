//
//  FPProductCheckoutCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/18/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductCheckoutCell: UITableViewCell {
    
    var cellHeight: CGFloat!
    
    var checkoutItem: FPCheckoutItem! {
        didSet {
            
            if let taxItem = checkoutItem as? FPCheckoutTaxItem {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    nameLabel.text = taxItem.tax.name + " (\(FPCurrencyFormatter.printableCurrency(taxItem.tax.rate))%)"
                    nameLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 21.0)
                    priceLabel.text = ""
                    quantityLabel.text = ""
                    totalLabel.text = "$\(FPCurrencyFormatter.printableCurrency(taxItem.sum))"
                } else {
                    let contentAttrText = NSMutableAttributedString()
                    
                    let nameText = taxItem.tax.name
                    let totalText = "$" + (FPCurrencyFormatter.printableCurrency(taxItem.sum))
                    
                    // Name
                    let productAttrText = NSMutableAttributedString(string: "Tax: " + nameText + " (\(FPCurrencyFormatter.printableCurrency(taxItem.tax.rate))%)")
                    contentAttrText.append(productAttrText)
                    
                    // Total
                    let totalAttrText = NSMutableAttributedString(string: "\nTotal: " + totalText)
                    contentAttrText.append(totalAttrText)
                    
                    let titles = ["Tax:", "Total:"]
                    for title in titles {
                        contentAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue", size: contentLabel.font.pointSize)!, range: (contentAttrText.string as NSString).range(of: title))
                    }
                    
                    contentLabel.attributedText = contentAttrText
                    contentLabel.frame.size.height = contentLabel.sizeThatFits(CGSize(width: contentLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cellHeight = contentLabel.frame.origin.y + contentLabel.frame.size.height + 10.0
                }
            } else if let cp = checkoutItem as? FPCheckoutProduct {
                
                var hasDiscount = cp.product.hasDiscount
                var discountPrice = cp.product.actualPrice
                
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    nameLabel.font = UIFont(name: "HelveticaNeue-Light", size: 21.0)
                    nameLabel.text = cp.product.name
                    quantityLabel.text = nf.string(from: NSNumber(value: cp.quantity))!
                    let priceText = FPCurrencyFormatter.printableCurrency(cp.product.price)
                    let priceAttrText = NSMutableAttributedString(string: priceText)
                    
                    if cp.isCSA {
                        nameLabel.text = nameLabel.text! + " (CSA Purchase)"
                        totalLabel.text = "$0.00"
                        discountPrice = 0.00
                        hasDiscount = true
                    } else {
                        totalLabel.text = "$\(FPCurrencyFormatter.printableCurrency(cp.sum))"
                    }
                    
                    if hasDiscount {
                        let discountText = FPCurrencyFormatter.printableCurrency(discountPrice)
                        priceAttrText.append(NSAttributedString(string: " / $\(discountText)", attributes: [NSForegroundColorAttributeName: FPColorGreen]))
                    }
                    
                    priceLabel.attributedText = priceAttrText
                } else {
                    let contentAttrText = NSMutableAttributedString()
                    
                    var productText = cp.product.name
                    let priceText = "$" + FPCurrencyFormatter.printableCurrency(cp.product.price)
                    let quantityText = nf.string(from: NSNumber(value:
                        cp.quantity))!
                    var totalText = "$" + (FPCurrencyFormatter.printableCurrency(cp.sum))
                    if cp.isCSA {
                        productText = productText + " (CSA Purchase)"
                        totalText = "$0.00"
                        discountPrice = 0.00
                        hasDiscount = true
                    }
                    
                    // Product name
                    let productAttrText = NSMutableAttributedString(string: "Product: " + productText)
                    contentAttrText.append(productAttrText)
                    
                    // Price
                    let priceAttrText = NSMutableAttributedString(string: "\nPrice: " + priceText)
                    if hasDiscount {
                        let discountText = FPCurrencyFormatter.printableCurrency(discountPrice)
                        priceAttrText.append(NSAttributedString(string: " / $\(discountText)", attributes: [NSForegroundColorAttributeName: FPColorGreen]))
                    }
                    contentAttrText.append(priceAttrText)
                    
                    // Quantity
                    let quantityAttrText = NSMutableAttributedString(string: "\nQuantity: " + quantityText)
                    contentAttrText.append(quantityAttrText)
                    
                    // Total
                    let totalAttrText = NSMutableAttributedString(string: "\nTotal: " + totalText)
                    contentAttrText.append(totalAttrText)
                    
                    let titles = ["Product:", "Price:", "Quantity:", "Total:"]
                    for title in titles {
                        contentAttrText.addAttribute(NSFontAttributeName, value: UIFont(name: "HelveticaNeue", size: contentLabel.font.pointSize)!, range: (contentAttrText.string as NSString).range(of: title))
                    }
                    
                    contentLabel.attributedText = contentAttrText
                    contentLabel.frame.size.height = contentLabel.sizeThatFits(CGSize(width: contentLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
                    cellHeight = contentLabel.frame.origin.y + contentLabel.frame.size.height + 10.0
                }
            }
        }
    }
    
    var nf: NumberFormatter!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var priceLabel: UILabel!
    @IBOutlet var quantityLabel: UILabel!
    @IBOutlet var totalLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    
    
    class func cellHeightForCheckoutItem(_ item: FPCheckoutItem) -> CGFloat {
        let nibName = UIDevice.current.userInterfaceIdiom == .pad ? "FPProductCheckoutCell-iPad" : "FPProductCheckoutCell"
        let cell = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?[0] as! FPProductCheckoutCell
        cell.checkoutItem = item
        return cell.cellHeight
    }
    
    override func awakeFromNib() {
        self.nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        
    }
}
