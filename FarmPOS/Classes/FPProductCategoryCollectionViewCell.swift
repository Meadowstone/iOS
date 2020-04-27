//
//  FPProductCategoryCollectionViewCell.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 28/05/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import SDWebImage

class FPProductCategoryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imgView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    
    override func awakeFromNib() {
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1.0
        self.clipsToBounds = true
    }
    
    var category: NSDictionary! {
        didSet {
            let product = category["product"] as! FPProduct
            let name = category["name"] as! String
            imgView.sd_setImage(with: product.imageURL, placeholderImage: UIImage(named: "category_placeholder"), options: [.refreshCached, .retryFailed])
            titleLabel.text = name
        }
    }

}
