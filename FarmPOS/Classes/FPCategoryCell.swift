//
//  FPCategoryCell.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import SDWebImage

class FPCategoryCell: UITableViewCell {
    
    var categoryInfo: NSDictionary! {
        didSet {
            categoryLabel.text = categoryInfo["name"] as? String
            imgView.sd_setImage(with: (categoryInfo["product"] as! FPProduct).imageURL, placeholderImage: UIImage(named: "category_placeholder"), options: [.refreshCached, .retryFailed])
        }
    }
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgView.layer.cornerRadius = imgView.frame.size.height / 2
        imgView.layer.borderColor = UIColor(red: 160.0 / 255.0, green: 160.0 / 255.0, blue: 160.0 / 255.0, alpha: 1.0).cgColor
        imgView.layer.borderWidth = 1.0
    }
    
}
