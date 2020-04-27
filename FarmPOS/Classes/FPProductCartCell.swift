//
//  FPProductCartCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/7/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductCartCell: UITableViewCell, FPProductCartCellViewDelegate {
    
    var delegate: FPProductCartCellDelegate?
    var cellViews: NSMutableArray!
    var objects: Array<AnyObject>! {
    didSet {
        let objCount = objects.count - 1
        for i in 0..<cellViews.count {
            let v = cellViews[i] as! FPProductCartCellView
            if i <= objCount {
                v.isHidden = false
                v.object = objects[i]
            }
            else {
                v.isHidden = true
            }
        }
    }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellViews = NSMutableArray(capacity: 3)
        var xOffset: CGFloat = 20.0
        for _ in 0..<3 {
            let v = Bundle.main.loadNibNamed("FPProductCartCellView", owner: nil, options: nil)?[0] as! FPProductCartCellView
            v.delegate = self
            v.frame = CGRect(x: xOffset, y: 7.0, width: v.bounds.size.width, height: v.bounds.size.height)
            contentView.addSubview(v)
            xOffset += v.bounds.size.width + 20.0
            cellViews.add(v)
        }
        selectionStyle = .none
    }
    
    
    func productCartCellViewDidPress(_ cellView: FPProductCartCellView) {
        delegate?.productCartCellDidSelect(self, object: cellView.object)
    }
    
}

@objc protocol FPProductCartCellDelegate {
    func productCartCellDidSelect(_ cell: FPProductCartCell, object: AnyObject)
}
