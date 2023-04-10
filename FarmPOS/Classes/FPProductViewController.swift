//
//  FPProductViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/8/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductViewController: FPRotationViewController, UIAlertViewDelegate, UITextFieldDelegate {
    
    var popover: UIPopoverController!
    var updating = false
    var existingCartProduct: FPCartProduct?
    var existingProductLabel: UILabel!
    var pricePerUnitLabel: UILabel!
    var totalPriceLabel: UILabel!
    var minusBtn: UIButton!
    var plusBtn: UIButton!
    var quantityLabel: UILabel!
    var cancelBtn: UIButton!
    var addBtn: UIButton!
    var cartProduct: FPCartProduct!
    var cartProductOriginal: FPCartProduct!
    weak var delegate: FPProductViewControllerDelegate?
    var numPadView: FPNumPadView?
    var scrollView: UIScrollView?
    var quantityTextField: UITextField?
    var notesTextField: UITextField?
    var notesDelimiterView: UIView?
    var preprice: Double!
    var isPound: Bool {
        return cartProduct.product.measurement.longName.lowercased().range(of: "pound", options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
    }
    var isOunce: Bool {
        return cartProduct.product.measurement.shortName.lowercased() == "oz"
    }
    
    
    class func productNavigationViewControllerForCartProduct(_ cartProduct: FPCartProduct, delegate: FPProductViewControllerDelegate, updating: Bool) -> UINavigationController {
        
        let vc = FPProductViewController()
        vc.updating = updating
        vc.delegate = delegate
        vc.cartProductOriginal = cartProduct
        
        let cp = FPCartProduct(product: cartProduct.product)
        cp.quantity = cartProduct.quantity
        cp.quantityPaid = cartProduct.quantityPaid
        vc.cartProduct = cp
        
        if !updating {
            vc.existingCartProduct = FPCartView.sharedCart().cartProductWithProduct(cartProduct.product)
        }
        
        return UINavigationController(rootViewController: vc)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = cartProduct.product.name
        navigationController!.navigationBar.barStyle = .black
        navigationController!.navigationBar.isTranslucent = false
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)
        }
        
        var yOffset: CGFloat = 20.0
        
        // Product exists
        if existingCartProduct != nil {
            existingProductLabel = UILabel(frame: CGRect(x: 20.0, y: yOffset, width: view.bounds.size.width - 40.0, height: 44.0))
            existingProductLabel.isUserInteractionEnabled = true
            existingProductLabel.adjustsFontSizeToFitWidth = true
            existingProductLabel.autoresizingMask = .flexibleWidth
            existingProductLabel.textAlignment = .center
            existingProductLabel.font = UIFont(name: "HelveticaNeue-Light", size: 24)!
            existingProductLabel.textColor = UIColor.darkGray
            view.addSubview(existingProductLabel)
            yOffset = existingProductLabel.frame.size.height + existingProductLabel.frame.origin.y + 8.0
        }
        
        // Notes
        let supportsNotes =
            cartProduct.product.rental ||
            cartProduct.product.name == "Miscellaneous"
        if supportsNotes {
            // Line
            notesDelimiterView = UIView(frame: CGRect(x: 20.0, y: yOffset, width: view.bounds.size.width - 40.0, height: 1.0))
            notesDelimiterView?.autoresizingMask = .flexibleWidth
            notesDelimiterView?.backgroundColor = FPColorGreen
            view.addSubview(notesDelimiterView!)
            
            yOffset += 1.0
            
            notesTextField = UITextField(frame: CGRect(x: 20.0, y: yOffset, width: view.bounds.size.width - 40.0, height: 48.0))
            notesTextField!.delegate = self
            notesTextField!.placeholder = cartProduct.product.rental ? "Rental notes" : "Notes"
            notesTextField!.attributedPlaceholder = NSAttributedString(string : notesTextField!.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            notesTextField!.autoresizingMask = .flexibleWidth
            notesTextField!.textAlignment = .center
            notesTextField!.backgroundColor = UIColor.clear
            notesTextField!.font = UIFont(name: "HelveticaNeue-Light", size: 26.0)
            notesTextField!.textColor = UIColor.darkGray
            notesTextField!.background = UIImage(named: "input_bg")
            view.addSubview(notesTextField!)
            
            yOffset = notesTextField!.frame.size.height + notesTextField!.frame.origin.y + 8.0
        }
        
        pricePerUnitLabel = UILabel(frame: CGRect(x: 20.0, y: yOffset, width: view.bounds.size.width - 40.0, height: 44.0))
        pricePerUnitLabel.isUserInteractionEnabled = true
        pricePerUnitLabel.adjustsFontSizeToFitWidth = true
        pricePerUnitLabel.autoresizingMask = .flexibleWidth
        pricePerUnitLabel.textAlignment = .center
        pricePerUnitLabel.attributedText = priceAttributedText()
        view.addSubview(pricePerUnitLabel)
        
        if !cartProduct.product.hasDefaultPrice {
            let r = UITapGestureRecognizer(target: self, action: #selector(FPProductViewController.selectPrice))
            pricePerUnitLabel.addGestureRecognizer(r)
        }
        
        totalPriceLabel = UILabel()
        totalPriceLabel.adjustsFontSizeToFitWidth = true
        totalPriceLabel.autoresizingMask = .flexibleWidth
        totalPriceLabel.textAlignment = .center
        totalPriceLabel.backgroundColor = UIColor.clear
        totalPriceLabel.font = UIFont(name: "HelveticaNeue-Light", size: 24.0)
        totalPriceLabel.textColor = UIColor.darkGray
        view.addSubview(totalPriceLabel)
        // Pound input for ounces
        if isPound || isOunce {
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                let editingHandler: (String) -> Void = {
                    [weak self] text in
                    self!.updateQuantityWithText(text)
                }
                numPadView = FPNumPadView.numPadViewForPounds(true, maxInputCount: Int.max, shouldShowDot: true, editingHanlder: editingHandler)
                numPadView!.textField.text = ""
                if isOunce {
                    numPadView!.textField.placeholder = "Enter weight in pounds"
                } else {
                    numPadView!.textField.placeholder = "Enter weight"
                }
                numPadView!.textField.attributedPlaceholder = NSAttributedString(string : numPadView!.textField.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
                
                view.addSubview(numPadView!)
            } else {
                quantityTextField = UITextField()
                quantityTextField!.placeholder = "Enter weight"
                quantityTextField!.attributedPlaceholder = NSAttributedString(string : quantityTextField!.placeholder!, attributes: [.foregroundColor: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
                
                quantityTextField!.autoresizingMask = .flexibleWidth
                quantityTextField!.textAlignment = .center
                quantityTextField!.backgroundColor = UIColor.clear
                quantityTextField!.font = UIFont(name: "HelveticaNeue-Light", size: 26.0)
                quantityTextField!.textColor = UIColor.darkGray
                quantityTextField!.addTarget(self, action: #selector(FPProductViewController.textFieldEditingChanged(_:)), for: .editingChanged)
                quantityTextField!.keyboardType = .decimalPad
                quantityTextField!.background = UIImage(named: "input_bg")
                quantityTextField!.becomeFirstResponder()
                
                let qiav = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 44.0))
                qiav.backgroundColor = UINavigationBar.appearance().barTintColor
                
                let titles = ["+0.25", "+0.50", "+0.75", "+1", "+2"]
                var titleXOffset: CGFloat = 0.0
                let width = view.bounds.size.width / CGFloat(titles.count)
                for title in titles {
                    let btn = UIButton(type: .custom) 
                    btn.setTitle(title, for: .normal)
                    btn.titleLabel!.font = UIFont(name: "HelveticaNeue", size: 20.0)
                    btn.setTitleColor(UIColor.white, for: .normal)
                    btn.frame = CGRect(x: titleXOffset, y: 0.0, width: width, height: qiav.bounds.size.height)
                    btn.addTarget(self, action: #selector(FPProductViewController.quantityBtnPressed(_:)), for: .touchUpInside)
                    titleXOffset += width
                    qiav.addSubview(btn)
                }
                
                quantityTextField!.inputAccessoryView = qiav
                
                NotificationCenter.default.addObserver(self, selector: #selector(FPProductViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(FPProductViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
                
                scrollView = UIScrollView(frame: view.bounds)
                scrollView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                scrollView!.backgroundColor = UIColor.clear
                view.addSubview(scrollView!)
                
                view.addSubview(quantityTextField!)
            }
        } else {
            let priceFrame = pricePerUnitLabel.frame
            let messageLabel = UILabel(frame: CGRect(x: 10.0, y: priceFrame.origin.y + priceFrame.size.height, width: view.bounds.width - 20.0, height: 39.0))
            messageLabel.textColor = UIColor.darkGray
            messageLabel.autoresizingMask = pricePerUnitLabel.autoresizingMask
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont(name:"HelveticaNeue-Light", size:20.0)
            messageLabel.adjustsFontSizeToFitWidth = true
            messageLabel.text = "Press the Plus/Minus signs to enter the quantity"
            view.addSubview(messageLabel)
            
            // Minus btn
            minusBtn = UIButton(type: .custom) 
            let minusImg = UIImage(named: "ipad_minus_btn")!
            minusBtn.setBackgroundImage(minusImg, for:.normal)
            minusBtn.frame = CGRect(x: 0.0, y: messageLabel.frame.size.height + messageLabel.frame.origin.y, width: minusImg.size.width, height: minusImg.size.height)
            minusBtn.addTarget(self, action: #selector(FPProductViewController.updateProductQuantity(_:)), for: .touchUpInside)
            view.addSubview(minusBtn)
            
            // Plus btn
            plusBtn = UIButton(type: .custom) 
            let plusImg = UIImage(named: "ipad_plus_btn")
            plusBtn.setBackgroundImage(plusImg, for:.normal)
            plusBtn.frame = minusBtn.frame
            plusBtn.addTarget(self, action: #selector(FPProductViewController.updateProductQuantity(_:)), for: .touchUpInside)
            view.addSubview(plusBtn)
            
            // Quantity label
            quantityLabel = UILabel()
            quantityLabel.font = UIFont(name: "HelveticaNeue-Light", size: 50.0)
            quantityLabel.textColor = UIColor.darkGray
            quantityLabel.textAlignment = .center
            quantityLabel.backgroundColor = UIColor.clear
            view.addSubview(quantityLabel)
        }
        
        cancelBtn = UIButton(type: .custom) 
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.setTitleColor(UIColor.white, for: .normal)
        cancelBtn.titleLabel!.font = UIFont(name: "HelveticaNeue", size: 20.0)
        cancelBtn.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        cancelBtn.addTarget(self, action: #selector(FPProductViewController.cancelPressed), for: .touchUpInside)
        view.addSubview(cancelBtn)
        
        addBtn = UIButton(type: .custom) 
        addBtn.setTitle(updating ? "Update" : "Add", for: .normal)
        addBtn.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        addBtn.addTarget(self, action: #selector(FPProductViewController.addPressed), for: .touchUpInside)
        addBtn.titleLabel!.font = UIFont(name: "HelveticaNeue", size: 20.0)
        view.addSubview(addBtn)
        
        if !cartProduct.product.hasDefaultPrice && cartProduct.product.price == 0.00 {
            self.selectPrice()
        }
        
        if isOunce {
            cartProduct.quantity = 0
            cartProduct.quantityPaid = cartProduct.quantity
            
        }
        
        self.layoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateProductQuantity(nil)
        
        if numPadView != nil {
            numPadView!.textField.text = cartProduct.quantity > 0 ? FPCurrencyFormatter.printableCurrency(cartProduct.quantity) : ""
        } else if quantityTextField != nil {
            quantityTextField!.text = cartProduct.quantity > 0 ? FPCurrencyFormatter.printableCurrency(cartProduct.quantity) : ""
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            self.popover.contentSize = CGSize(width: self.preferredContentSize.width, height: self.preferredContentSize.height + self.navigationController!.navigationBar.frame.size.height)
        }
    }
    
    func priceAttributedText() -> NSAttributedString {
        // Price per unit
//        let priceText  = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.product.price + cartProduct.product.baseTaxValue)
        let priceText  = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.product.price)
        
        var priceAttrText: NSMutableAttributedString
        
        if isOunce {
            priceAttrText = NSMutableAttributedString(string: "Price per ounce: \(priceText)", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 24)!, .foregroundColor: UIColor.darkGray])
        } else {
            priceAttrText = NSMutableAttributedString(string: "Price per \(cartProduct.product.measurement.longName.capitalized): \(priceText)", attributes: [.font: UIFont(name: "HelveticaNeue-Light", size: 24)!, .foregroundColor: UIColor.darkGray])
        }
        
        let priceRange = (priceAttrText.string as NSString).range(of: priceText)
        priceAttrText.addAttributes([.foregroundColor: FPColorGreen, .font: UIFont(name: "HelveticaNeue", size: 30.0)!], range: priceRange)
        
        if cartProduct.product.hasDiscount {
//            let discountText = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.product.actualPriceWithTax)
            let discountText = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.product.actualPrice)
            let discountAttrText = NSMutableAttributedString(string: " / \(discountText)")
            let discountRange = (discountAttrText.string as NSString).range(of: discountText)
            discountAttrText.addAttributes([.foregroundColor: FPColorGreen, .font: UIFont(name: "HelveticaNeue", size: 30.0)!], range: discountRange)
            priceAttrText.append(discountAttrText)
            priceAttrText.addAttribute(.strikethroughStyle, value: NSNumber(value: NSUnderlineStyle.single.rawValue as Int), range: priceRange)
        }
        
        if !cartProduct.product.hasDefaultPrice {
            priceAttrText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: priceRange)
        }
        
        return priceAttrText
    }
    
    @objc func selectPrice() {
        self.preprice = self.cartProduct.product.price
        let vc = FPSelectPriceViewController.selectPriceViewControllerWithPriceSelectedHandler({ [weak self] (price) -> Void in
            self!.cartProduct.product.price = price
            self!.cartProduct.product.discountPrice = self!.cartProduct.product.price
            self!.pricePerUnitLabel.attributedText = self!.priceAttributedText()
            self!.updateProductQuantity(nil)
            _ =
                self!.navigationController?.popViewController(animated: true)
            })
        vc.popover = popover
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func textFieldEditingChanged(_ sender: UITextField) {
        if (sender.text! as NSString).length > 0 {
            let text = (sender.text! as NSString).substring(from: (sender.text! as NSString).length - 1)
            sender.text = (sender.text! as NSString).substring(to: (sender.text! as NSString).length - 1)
            let t = FPInputValidator.preprocessCurrencyText(text, relativeTo: sender.text!)
            if FPInputValidator.shouldAddString(t, toString: sender.text!, maxInputCount: Int.max, isDecimal: true) {
                sender.text = sender.text! + t
            }
        }
        updateQuantityWithText(sender.text!)
    }
    
    func updateQuantityWithText(_ text: String) {
        if (text as NSString).length > 0 {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "en_US")
            nf.numberStyle = .decimal
            if let n = nf.number(from: text) {
                if isOunce {
                    // To pounds
                    cartProduct.quantity = n.doubleValue * 16.0
                } else {
                    cartProduct.quantity = n.doubleValue
                }
            }
        } else {
            cartProduct.quantity = 0.0
        }
        updateProductQuantity(nil)
    }
    
    @objc func quantityBtnPressed(_ btn: UIButton) {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        var cn = 0.0
        if (quantityTextField!.text! as NSString).length > 0 {
            cn = nf.number(from: quantityTextField!.text!) as! Double
        }
        let tn = nf.number(from: (btn.title(for: .normal)! as NSString).substring(from: 1)) as! Double
        quantityTextField!.text = nf.string(from: NSNumber(value: cn + tn))!
        updateQuantityWithText(quantityTextField!.text!)
    }
    
    func layoutSubviews() {
        
        var width: CGFloat = popoverWidth
        var xOffset: CGFloat = 20.0
        var totalPriceLabelWidth: CGFloat = 420.0
        var buttonWidth: CGFloat = 190.0
        if UIDevice.current.userInterfaceIdiom == .phone {
            width = view.bounds.size.width
            xOffset = 10.0
            totalPriceLabelWidth = 300.0
            buttonWidth = 130.0
        }
        
        if let ep = existingCartProduct {
            let str = NSMutableAttributedString(string: "This item is currently in your cart.  Did you want to update the quantity from \(ep.quantity) to \(ep.quantity + cartProduct.quantity)?")
            str.addAttribute(.font, value: UIFont(name: "HelveticaNeue-Bold", size: 24.0)!, range: (str.string as NSString).range(of: "\(ep.quantity)"))
            str.addAttribute(.font, value: UIFont(name: "HelveticaNeue-Bold", size: 24.0)!, range: (str.string as NSString).range(of: "\(ep.quantity + cartProduct.quantity)", options: .backwards))
            existingProductLabel.attributedText = str
        }
        
        if plusBtn != nil {
            quantityLabel.text = "\(Int(cartProduct.quantity))"
            quantityLabel.sizeToFit()
            
            let distance: CGFloat = 12.0
            let minusOffset: CGFloat = (width - (plusBtn.bounds.size.width + minusBtn.bounds.size.width + quantityLabel.bounds.size.width + distance * 2.0)) / 2.0
            minusBtn.frame.origin.x = minusOffset
            quantityLabel.frame.origin = CGPoint(x: minusBtn.bounds.size.width + minusBtn.frame.origin.x + distance, y: minusBtn.frame.origin.y + (minusBtn.frame.size.height - quantityLabel.frame.size.height) / 2.0)
            plusBtn.frame.origin.x = quantityLabel.bounds.size.width + quantityLabel.frame.origin.x + distance
            totalPriceLabel.frame = CGRect(x: (width - totalPriceLabelWidth) / 2, y: plusBtn.frame.origin.y + plusBtn.bounds.size.height + 16.0, width: totalPriceLabelWidth, height: 33.0)
        } else {
            totalPriceLabel.frame = pricePerUnitLabel.frame.offsetBy(dx: 0.0, dy: pricePerUnitLabel.bounds.size.height)
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                numPadView!.frame = CGRect(x: (width - numPadView!.frame.size.width) / 2.0, y: totalPriceLabel.bounds.size.height + totalPriceLabel.frame.origin.y + 8.0, width: numPadView!.bounds.size.width, height: numPadView!.bounds.size.height)
            } else {
                quantityTextField!.frame = CGRect(x: xOffset, y: totalPriceLabel.bounds.size.height + totalPriceLabel.frame.origin.y + 8.0, width: width - xOffset * 2.0, height: 48.0)
            }
        }
        
        var v: UIView = view
        if scrollView != nil && scrollView!.subviews.count == 0 {
            for subview in view.subviews {
                if subview !== scrollView {
                    scrollView!.addSubview(subview)
                }
            }
        } else if scrollView != nil && scrollView!.subviews.count > 0 {
            v = scrollView!
        }
        
        let lv = v.lastViewIgnoringViews([cancelBtn, addBtn])!
        cancelBtn.frame = CGRect(x: (width - (buttonWidth * 2.0 + xOffset * 2.0)) / 2.0, y: lv.frame.size.height + lv.frame.origin.y + 20.0, width: buttonWidth, height: 40.0)
        addBtn.frame = CGRect(x: cancelBtn.frame.origin.x + cancelBtn.frame.size.width + xOffset * 2.0, y: cancelBtn.frame.origin.y, width: cancelBtn.frame.size.width, height: cancelBtn.frame.size.height)
        
        let size = CGSize(width: width, height: addBtn.bounds.size.height + addBtn.frame.origin.y + 20.0)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            preferredContentSize = size
        } else if isPound || isOunce {
            scrollView!.contentSize = size
        }
        
        if updating {
            if FPCurrencyFormatter.intCurrencyRepresentation(cartProduct.quantity) == 0 {
                addBtn.setTitle("Remove", for: .normal)
            } else {
                addBtn.setTitle("Update", for: .normal)
            }
        }
        
    }
    
    @objc func updateProductQuantity(_ sender: UIButton?) {
        if minusBtn != nil {
            if sender === minusBtn {
                cartProduct.quantity = max(0, cartProduct.quantity - 1)
            } else if sender === plusBtn {
                cartProduct.quantity += 1
            }
        }
        
        cartProduct.quantityPaid = cartProduct.quantity
        
//        let priceText = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.sumWithTax)
        let priceText = "$" + FPCurrencyFormatter.printableCurrency(cartProduct.sum)
        var priceAttrText: NSMutableAttributedString!
        if isOunce {
            priceAttrText = NSMutableAttributedString(string: "Total Price: \(FPCurrencyFormatter.printableCurrency(cartProduct.quantityPaid)) \(cartProduct.product.measurement.longName)(s) = \(priceText)")
        } else {
            priceAttrText = NSMutableAttributedString(string: "Total Price: \(priceText)")
        }
        let priceRange = (priceAttrText.string as NSString).range(of: priceText)
        priceAttrText.addAttributes([.foregroundColor: FPColorRed, .font: UIFont(name: "HelveticaNeue", size: 30.0)!], range: priceRange)
        totalPriceLabel.attributedText = priceAttrText
        
        self.layoutSubviews()
    }
    
    @objc func cancelPressed() {
        if preprice != nil {
            cartProduct.product.price = preprice
            cartProduct.product.discountPrice = cartProduct.product.price
        }
        delegate?.productViewControllerDidCancel(self)
    }
    
    @objc func addPressed() {
        
        if delegate == nil {
            FPAlertManager.showMessage("Delegate not set", withTitle: "Critical Error")
            return
        }
        
        if updating && FPCurrencyFormatter.intCurrencyRepresentation(cartProduct.quantity) == 0 {
            delegate?.productViewControllerDidRemove(self, cartProduct: self.cartProductOriginal)
            return
        }
        
        if FPCurrencyFormatter.intCurrencyRepresentation(cartProduct.quantity) == 0 {
            FPAlertManager.showMessage("Enter valid quantity", withTitle: "Error")
            return
        }
        //        if cartProduct.product.price == 0.00 {
        //            FPAlertManager.showMessage("Enter price", withTitle: "Error")
        //            return
        //        }
        
        if let ntf = notesTextField {
            cartProduct.notes = ntf.text!
        }
        
        delegate?.productViewControllerDidAdd(self, cartProduct: cartProduct)
    }
    
    //MARK: Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        scrollView!.contentInset = insets
        scrollView!.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if var kbRect = (note.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            kbRect = FPAppDelegate.instance().window!.convert(kbRect, to: view)
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    @objc func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
    // UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 1 {
            let text = alertView.textField(at: 0)!.text!
            var price = 0.00
            if (text as NSString).length > 0 {
                let nf = NumberFormatter()
                nf.locale = Locale(identifier: "en_US")
                let n: NSNumber? = nf.number(from: text)
                var d = 0.00
                if n != nil {
                    d = n!.doubleValue
                }
                price = d
            }
            cartProduct.product.price = price
            cartProduct.product.discountPrice = cartProduct.product.price
            pricePerUnitLabel.attributedText = priceAttributedText()
            updateProductQuantity(nil)
        }
    }
    
    // UITextField delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField === notesTextField {
            return true
        }
        
        if (string as NSString).length == 0 {
            return true
        }
        
        let cs = CharacterSet(charactersIn: "0123456789.")
        if (string as NSString).rangeOfCharacter(from: cs).length == 0 {
            return false
        }
        
        return FPInputValidator.shouldAddString(string, toString: textField.text!, maxInputCount: Int.max, isDecimal: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === notesTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}

@objc protocol FPProductViewControllerDelegate {
    func productViewControllerDidCancel(_ pvc: FPProductViewController)
    func productViewControllerDidAdd(_ pvc: FPProductViewController, cartProduct: FPCartProduct)
    func productViewControllerDidRemove(_ pvc: FPProductViewController, cartProduct: FPCartProduct)
}
