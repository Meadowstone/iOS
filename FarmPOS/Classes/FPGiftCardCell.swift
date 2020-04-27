//
//  FPGiftCardCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPGiftCardCell: UITableViewCell {
    
    var delegate: FPGiftCardCellDelegate?
    var giftCard: FPGiftCard! {
    didSet {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        let sumText = nf.string(from: NSNumber(value: giftCard.sum))!
        let sumAttrText = NSMutableAttributedString(string: "Gift Card - $\(sumText)")
        let sumRange = (sumAttrText.string as NSString).range(of: sumText)
        sumAttrText.addAttributes([NSForegroundColorAttributeName: FPColorGreen, NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 25.0)!], range: sumRange)
        titleLabel.attributedText = sumAttrText

        buyBtn.setTitle("Buy ($\(sumText))", for: .normal)
    }
    }

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var buyBtn: UIButton!
    
    @IBAction func buyPressed(_ sender: AnyObject) {
        delegate?.giftCardCellDidPressBuy(self)
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        selectionStyle = .none
    }

}

@objc protocol FPGiftCardCellDelegate {
    func giftCardCellDidPressBuy(_ cell: FPGiftCardCell)
}
