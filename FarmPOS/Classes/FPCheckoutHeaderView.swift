//
//  FPCheckoutHeaderView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/18/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPCheckoutHeaderView: UIView {
    
    var hasDiscounts: Bool = false {
        didSet {
            if let pl = priceLabel {
                if hasDiscounts {
                    pl.text = "Unit Price / Special Price"
                } else {
                    pl.text = "Unit Price"
                }
            }
        }
    }
    
    @IBOutlet var buyBtn: UIButton!
    @IBOutlet var priceLabel: UILabel?
    
    class func checkoutHeaderView() -> FPCheckoutHeaderView {
        let nibName = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? "FPCheckoutHeaderView-iPad" : "FPCheckoutHeaderView"
        let view = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?[0] as! FPCheckoutHeaderView
        return view
    }
    
}
