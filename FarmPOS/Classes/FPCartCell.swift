//
//  FPCartCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/8/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import SDWebImage

class FPCartCell: UITableViewCell {
    
    var nf: NumberFormatter?
    
    weak var delegate: FPCartCellDelegate?
    var cellHeight: CGFloat = 0.0
    var cartProduct: FPCartProduct! {
        didSet {
            
            if nf == nil {
                nf = NumberFormatter()
                nf!.locale = Locale(identifier: "en_US")
                nf!.numberStyle = .decimal
                nf!.maximumFractionDigits = 2
            }
            
            imgView.sd_setImage(with: cartProduct.product.imageURL, placeholderImage: UIImage(named: "category_placeholder"), options: [.refreshCached, .retryFailed])
            
            let contentAttrText = NSMutableAttributedString()
            
            let nameText = NSAttributedString(string: "\(cartProduct.product.name) X \(nf!.string(from: NSNumber(value: cartProduct.quantity))!) \(cartProduct.product.measurement.shortName)", attributes:[.font: UIFont(name: "HelveticaNeue-Medium", size: 16.0)!])
            contentAttrText.append(nameText)
            
            if cartProduct.quantityPaid > 0.0 {
                let sumText = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.sum)
                let priceText = FPCurrencyFormatter.printableCurrency(cartProduct.product.actualPrice)
                let sumAttrText = NSMutableAttributedString(string: "\n\(nf!.string(from: NSNumber(value: cartProduct.quantityPaid))!)  X  $\(priceText) = \(sumText)", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 16.0)!, .foregroundColor: UIColor.darkGray])
                sumAttrText.addAttribute(.foregroundColor, value: FPColorRed, range: (sumAttrText.string as NSString).range(of: sumText, options: .backwards))
                contentAttrText.append(sumAttrText)
            }
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            paragraphStyle.lineSpacing = 2.0
            contentAttrText.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, (contentAttrText.string as NSString).length))
            
            contentLabel.attributedText = contentAttrText
            deleteBtn.frame.origin.x = self.contentView.bounds.size.width - (8.0 + deleteBtn.frame.size.width)
            let width = self.contentView.frame.size.width - (76.0 + deleteBtn.frame.size.width + 16.0)
            
            let size = contentLabel.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
            contentLabel.frame = CGRect(x: contentLabel.frame.origin.x, y: contentLabel.frame.origin.y, width: width, height: max(size.height, imgView.bounds.size.height))
            
            let lastView = contentView.lastView()!
            cellHeight = max(lastView.frame.size.height + lastView.frame.origin.y + 5.0, imgView.frame.size.height + 10.0)
        }
    }
    
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var contentLabel: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    
    
    @IBAction func deletePressed(_ sender: AnyObject) {
        delegate?.cartCellDeletePressed(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.layer.cornerRadius = imgView.frame.size.height / 2
        imgView.layer.borderColor = UIColor(red: 160.0 / 255.0, green: 160.0 / 255.0, blue: 160.0 / 255.0, alpha: 1.0).cgColor
        imgView.layer.borderWidth = 1.0
        separatorInset = UIEdgeInsets.zero
    }
    
    class func heightWithCartProduct(_ cartProduct: FPCartProduct) -> CGFloat {
        let cell = Bundle.main.loadNibNamed("FPCartCell", owner: nil, options: nil)?[0] as! FPCartCell
        cell.cartProduct = cartProduct
        return cell.cellHeight
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        deleteBtn.isHidden = editing
    }
    
}

@objc protocol FPCartCellDelegate {
    func cartCellDeletePressed(_ cell: FPCartCell)
}
