//
//  FPOrderCell.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/16/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPOrderCell: UITableViewCell {
    
    var df: DateFormatter?
    var delegate: FPOrderCellDelegate?
    var cellHeight: CGFloat = 0.0
    var order: FPOrder! {
    didSet {
        let contentAttrText = NSMutableAttributedString(string: "\(order.customer.name)", attributes: [.foregroundColor: FPColorGreen, .font: UIFont(name: "HelveticaNeue-Medium", size: 19.0)!])
        
        // Email
        contentAttrText.append(NSAttributedString(string: "\nEmail: ", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 17.0)!, .foregroundColor: FPColorGreen]))
        contentAttrText.append(NSAttributedString(string: "\(order.customer.email)", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 19.0)!, .foregroundColor: FPColorDarkGray]))
        
        // Phone
        contentAttrText.append(NSAttributedString(string: "\nPhone: ", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 17.0)!, .foregroundColor: FPColorGreen]))
        contentAttrText.append(NSAttributedString(string: "\(order.customer.phone)", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 19.0)!, .foregroundColor: FPColorDarkGray]))
        
        // Due date
        contentAttrText.append(NSAttributedString(string: "\nDue: ", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 17.0)!, .foregroundColor: FPColorGreen]))
        contentAttrText.append(NSAttributedString(string: "\(df!.string(from: order.dueDate as Date))", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 19.0)!, .foregroundColor: FPColorDarkGray]))
        
        // Delivery to
        if order.shippingOption != FPOrder.ShippingOption.farmstand {
            var addressItems = [String]()
            if (order.address as NSString).length > 0 {
                addressItems.append(order.address)
            }
            if (order.city as NSString).length > 0 {
                addressItems.append(order.city)
            }
            if (order.state as NSString).length > 0 {
                addressItems.append(order.state)
            }
            if (order.zipCode as NSString).length > 0 {
                addressItems.append(order.zipCode)
            }
            
            if addressItems.count > 0 {
                contentAttrText.append(NSAttributedString(string: "\nDelivery to: ", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 17.0)!, .foregroundColor: FPColorGreen]))
                let joiner = ", "
                contentAttrText.append(NSAttributedString(string: "\((addressItems as NSArray).componentsJoined(by: joiner))", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 19.0)!, .foregroundColor: FPColorDarkGray]))
            }
        }

        // Delivery type
        contentAttrText.append(NSAttributedString(string: "\nDelivery type: ", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 17.0)!, .foregroundColor: FPColorGreen]))
        contentAttrText.append(NSAttributedString(string: "\(order.shippingOption.toString())", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 19.0)!, .foregroundColor: FPColorDarkGray]))
        
        contentLabel.attributedText = contentAttrText
        contentLabel.frame.size.width = UIScreen.main.bounds.size.width - 25.0
        contentLabel.frame.size.height = contentLabel.sizeThatFits(CGSize(width: UIScreen.main.bounds.size.width - 25.0, height: CGFloat.greatestFiniteMagnitude)).height
        cancelBtn.frame.origin.y = contentLabel.frame.origin.y + contentLabel.frame.size.height + 8.0
        cellHeight = cancelBtn.frame.origin.y + cancelBtn.frame.size.height + 10.0
    }
    }

    @IBOutlet var contentLabel: UILabel!
    @IBOutlet var cancelBtn: UIButton!
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        delegate?.orderCellDidPressCancel(self)
    }
    
    
    class func cellHeightForOrder(_ order: FPOrder) -> CGFloat {
        let oc = Bundle.main.loadNibNamed("FPOrderCell", owner: nil, options: nil)?[0] as! FPOrderCell
        oc.bounds = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: oc.bounds.size.height)
        oc.order = order
        return oc.cellHeight
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if df == nil {
            df = DateFormatter()
            df!.timeZone = TimeZone.autoupdatingCurrent
            df!.dateFormat = "dd MMM yyyy hh:mm a"
        }
        selectionStyle = .none
        cancelBtn.backgroundColor = UINavigationBar.appearance().barTintColor
    }
}

@objc protocol FPOrderCellDelegate {
    func orderCellDidPressCancel(_ cell: FPOrderCell)
}
