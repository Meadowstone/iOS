//
//  FPCartHeaderView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/8/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPCartHeaderView: UIView {

    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var checkoutBtn: UIButton!
    @IBOutlet weak var sumLabel: UILabel!
    @IBOutlet weak var taxLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var taxAmountLabel: UILabel!
    @IBOutlet weak var totalAmountLabel: UILabel!
    
    weak var cartView: FPCartView!
    
    class func cartHeaderView() -> FPCartHeaderView {
        let cartHeaderView = Bundle.main.loadNibNamed("FPCartHeaderView", owner: nil, options: nil)?[0] as! FPCartHeaderView
        return cartHeaderView
    }
    
    func displaySum(_ sum: Double, tax: Double) {
        self.sumLabel.text = "$" + FPCurrencyFormatter.printableCurrency(sum)
        
        let taxHidden = tax <= 0
        self.taxLabel.isHidden = taxHidden
        self.taxAmountLabel.isHidden = taxHidden
        self.totalAmountLabel.isHidden = taxHidden
        self.totalLabel.isHidden = taxHidden
        
        if !taxHidden {
            self.taxAmountLabel.text = "$" + FPCurrencyFormatter.printableCurrency(tax)
            self.totalAmountLabel.text = "$" + FPCurrencyFormatter.printableCurrency(tax + sum)
        }
        
        self.checkoutBtn.isHidden = true
        let lastView = self.lastView()!
        self.checkoutBtn.frame.origin.y = lastView.frame.maxY + 8
        self.checkoutBtn.isHidden = cartView.cartProducts.count == 0
        
        self.updateFrame()
    }
    
    func updateFrame() {
        let lastView = self.lastView()!
        self.frame.size.height = lastView.frame.maxY + 20
    }
    
}
