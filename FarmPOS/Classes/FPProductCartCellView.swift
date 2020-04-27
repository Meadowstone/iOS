//
//  FPProductCartCellView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/7/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import SDWebImage

class FPProductCartCellView: UIView {
        
    var delegate: FPProductCartCellViewDelegate?
    var object: AnyObject! {
        didSet {
            if let product = object as? FPProduct {
                imageView.sd_setImage(with: product.imageURL, placeholderImage: UIImage(named: "category_placeholder"), options: [.refreshCached, .retryFailed])
                availableFromView.isHidden = product.onSaleNow
                productNameLabel.text = product.name
                if let d = product.availableFrom {
                    let df = DateFormatter()
                    df.dateFormat = "MMM yyyy"
                    availableFromLabel.text = "Avilable from: " + df.string(from: d as Date)
                }
                saleImageView.isHidden = (product.availableFrom != nil || product.dayDiscount == nil)
            } else if let ci = object as? NSDictionary {
                let product = ci["product"] as! FPProduct
                let name = ci["name"] as! String
                imageView.sd_setImage(with: product.imageURL, placeholderImage: UIImage(named: "category_placeholder"), options: [.refreshCached, .retryFailed])
                availableFromView.isHidden = true
                productNameLabel.text = name
                saleImageView.isHidden = true
            }
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var availableFromView: UIView!
    @IBOutlet weak var availableFromLabel: UILabel!
    @IBOutlet weak var productNameLabel: UILabel!
    @IBOutlet weak var saleImageView: UIImageView!
    
    @IBAction func btnPressed(_ sender: AnyObject) {
        delegate?.productCartCellViewDidPress(self)
    }
    
}

@objc protocol FPProductCartCellViewDelegate {
    func productCartCellViewDidPress(_ cellView: FPProductCartCellView)
}
