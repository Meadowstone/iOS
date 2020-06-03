//
//  FPCartView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

var _sharedCart: FPCartView?
class FPCartView: UIView, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, FPCartCellDelegate {
    
    var tableView: UITableView!
    var cartProducts = [FPCartProduct]()
    var delegate: FPCartViewDelegate?
    var headerView: FPCartHeaderView!
    var applicableBalance = 0.0
    var sum = 0.0
    var includeOutstandingBalance = false
    var checkoutSum: Double {
        var s = sum
        if let ac = FPCustomer.activeCustomer() {
            s -= applicableBalance
            if includeOutstandingBalance {
                s += abs(ac.balance)
            }
        }
        s += self.totalTaxSum()
        return s
    }
    var sumWithTax: Double {
        return self.sum + self.totalTaxSum()
    }
    
    var applicableFarmBucks: Double {
        var applicableFarmBucks = 0.00
        if let ac = FPCustomer.activeCustomer() {
            let maxFarmBucks = ac.farmBucks
            for p in cartProducts {
                if applicableFarmBucks == maxFarmBucks {
                    break
                }
                if p.product.grownOnFarm {
                    applicableFarmBucks = min(maxFarmBucks, applicableFarmBucks + p.sumWithTax)
                }
            }
        }
        return applicableFarmBucks
    }
    
    
    class func sharedCart() -> FPCartView {
        if _sharedCart == nil {
            self.setup()
        }
        return _sharedCart!
    }
    
    class func setup() {
        _ = self.cartViewWithFrame(CGRect(x: 0.0, y: 0.0, width: 300.0, height: 127.0))
    }
    
    class func cartViewWithFrame(_ frame: CGRect) -> FPCartView {
        let cv = FPCartView(frame: frame)
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cv.backgroundColor = UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)
        
        NotificationCenter.default.addObserver(cv, selector: #selector(FPCartView.processOrderOrTransaction), name: NSNotification.Name(rawValue: FPTransactionOrOrderProcessingNotification), object: nil)
        
        let tableView = UITableView(frame: cv.bounds)
        tableView.autoresizingMask = cv.autoresizingMask
        tableView.register(UINib(nibName: "FPCartCell", bundle: nil), forCellReuseIdentifier: "FPCartCell")
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.delegate = cv
        tableView.dataSource = cv
        cv.addSubview(tableView)
        cv.tableView = tableView
        
        let headerView = FPCartHeaderView.cartHeaderView()
        headerView.cartView = cv
        headerView.frame = CGRect(x: 0.0, y: 0.0, width: cv.bounds.size.width, height: headerView.bounds.size.height)
        headerView.resetBtn.addTarget(cv, action: #selector(FPCartView.resetPressed), for: .touchUpInside)
        headerView.checkoutBtn.addTarget(cv, action: #selector(FPCartView.checkoutPressed), for: .touchUpInside)
        headerView.checkoutBtn.frame = CGRect(x: 10.0, y: headerView.checkoutBtn.frame.origin.y, width: headerView.bounds.size.width - 20.0, height: headerView.checkoutBtn.bounds.size.height)
        cv.headerView = headerView
        tableView.tableHeaderView = headerView
        
        cv.updateSum()
        _sharedCart = cv
        
        return cv
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func processOrderOrTransaction() {
        var cartProductsInfo: [NSDictionary]?
        if let order = FPOrder.activeOrder() {
            cartProductsInfo = order.cartProductsInfo
        }
        if let c = FPCustomer.activeCustomer() {
            if let cpi = c.voidTransactionProducts {
                cartProductsInfo = cpi
                if c.email == "anonymous@farmlogger.com" {
                    FPCustomer.setActiveCustomer(nil)
                }
            }
        }
        
        if cartProductsInfo == nil {
            return
        }
        
        self.resetCart()
        for pi in cartProductsInfo! {
            let products = FPProduct.allProducts()!.filter({ $0.id == pi["product_id"] as! Int})
            if products.count > 0 {
                let cp = FPCartProduct(product: products[0])
                cp.quantity = 0.0
                
                if let discount = pi["discount"] as? Double {
                    var p = cp.product.price
                    p = FPCurrencyFormatter.roundCrrency(p - (discount / 100.00) * p)
                    if cp.product.discountPrice < p {
                        p = cp.product.discountPrice
                    }
                    cp.product.discountPrice = p
                    cp.product.orderDiscount = discount
                }
                
                if let q = pi["quantity_paid"] as? Double {
                    cp.quantityPaid = q
                    cp.quantity += q
                }
                
                for ci in pi["csa_used"] as! [NSDictionary] {
                    let quantity = ci["quantity"] as! Double
                    let creditsUsed = ci["credits_used"] as! Int
                    cp.quantityCSA += quantity
                    cp.quantity += quantity
                    cp.csaCreditsUsed += creditsUsed
                    
                    let productCsa = cp.product.csas.filter {
                        return $0.id == ci["id"] as! Int
                        }[0]
                    productCsa.limit += cp.csaCreditsUsed
                    productCsa.creditsUsed = creditsUsed
                }
                self.addCartProduct(cp, updating: false)
            }
        }
        
        FPCustomer.activeCustomer()?.voidTransactionProducts = nil
    }
    
    func hasDicounts() -> Bool {
        var hasDiscounts = false
        for cp in cartProducts {
            if cp.product.hasDiscount {
                hasDiscounts = true
                break
            }
        }
        return hasDiscounts
    }
    
    func totalTaxSumForTax(_ tax: FPProductCategoryTax) -> Double {
        var totalTaxSumForTax = 0.0
        
        let taxProducts = cartProducts.filter({ (cartProduct) -> Bool in
            var shouldReturn = false
            if let t = cartProduct.product.category.tax {
                shouldReturn = tax.id == t.id
            }
            return shouldReturn
        })
        
//        var sum = 0.0
        for cp in taxProducts {
//            sum += cp.sum
            totalTaxSumForTax += FPCurrencyFormatter.roundCrrency((cp.sum / 100) * tax.rate)
        }
        
//        totalTaxSumForTax = FPCurrencyFormatter.roundCrrency((sum / 100.0) * tax.rate)
        
        return totalTaxSumForTax
    }
    
    func totalTaxSum() -> Double {
        var taxes = [FPProductCategoryTax]()
        for cp in self.cartProducts {
            if let tax = cp.product.category.tax {
                let exists = taxes.filter({ (filterTax) -> Bool in
                    return tax.id == filterTax.id
                }).count > 0
                if !exists {
                    taxes.append(tax)
                }
            }
        }
        
        var totalTaxSum = 0.0
        for tax in taxes {
            totalTaxSum += self.totalTaxSumForTax(tax)
        }
        return FPCurrencyFormatter.roundCrrency(totalTaxSum)
    }
    
    func checkoutItems() -> [FPCheckoutItem] {
        var checkoutItems = [FPCheckoutItem]()
        var noTaxCartProducts = [FPCartProduct]()
        var taxes = [FPProductCategoryTax]()
        
        // Generate taxes and no tax cart products
        for cp in self.cartProducts {
            if let tax = cp.product.category.tax {
                let exists = taxes.filter({ (filterTax) -> Bool in
                    return tax.id == filterTax.id
                }).count > 0
                if !exists {
                    taxes.append(tax)
                }
            } else {
                noTaxCartProducts.append(cp)
            }
        }
        
        taxes.sort { (t1, t2) -> Bool in
            return t1.name < t2.name
        }
        
        let appendCartProduct: ( _ : FPCartProduct) -> Void = { (cp: FPCartProduct) in
            let product = cp.product
            var quantity = 0.0
            let sum = cp.sum
            if cp.quantityPaid > 0.0 {
                quantity = cp.quantityPaid
                checkoutItems.append(FPCheckoutProduct(product: product, quantity: quantity, sum: sum!, isCSA: false))
            }
            if cp.quantityCSA > 0.0 {
                quantity = cp.quantityCSA
                checkoutItems.append(FPCheckoutProduct(product: product, quantity: quantity, sum: 0.0, isCSA: true))
            }
        }
        
        // Append products that fall under tax category
        for tax in taxes {
            var taxCartProducts = cartProducts.filter({ (cartProduct) -> Bool in
                var shouldReturn = false
                if let t = cartProduct.product.category.tax {
                    shouldReturn = tax.id == t.id
                }
                return shouldReturn
            })
            
            taxCartProducts.sort { (p1, p2) -> Bool in
                return p1.product.name < p2.product.name
            }
            
            for cp in taxCartProducts {
                appendCartProduct(cp)
            }
            
            let sum = self.totalTaxSumForTax(tax)
            let taxItem = FPCheckoutTaxItem(tax: tax, sum: sum)
            checkoutItems.append(taxItem)
        }
        
        for cp in noTaxCartProducts {
            appendCartProduct(cp)
        }
        
        return checkoutItems
    }
    
    // Used by checkout controller to construct the products info
    func paymentProducts() -> [NSDictionary] {
        var paymentProducts = [NSDictionary]()
        for cp in cartProducts {
            var pInfo = [String: Any]()
            pInfo["product_id"] = cp.product.id
            pInfo["quantity_paid"] = cp.quantityPaid
            pInfo["base_price"] = cp.product.price
            pInfo["display_price"] = cp.product.actualPrice
            
            if let tax = cp.product.category.tax {
                pInfo["tax_id"] = tax.id
                pInfo["tax_rate"] = tax.rate
                pInfo["tax_amount"] = cp.taxSumRaw
            }
            
            if let dd = cp.product.dayDiscount {
                let discount = dd.discount
                var p = cp.product.price
                p = FPCurrencyFormatter.roundCrrency(p - (discount / 100.00) * p)
                if cp.product.discountPrice > p {
                    pInfo["discount"] = dd.discount
                }
            } else if let d = cp.product.orderDiscount {
                pInfo["discount"] = d
            }
            
            if !cp.product.hasDefaultPrice {
                pInfo["price"] = cp.product.price
            }
            
            if cp.product.rental {
                pInfo["notes"] = cp.notes
            }
            
            var csaUsed = [NSDictionary]()
            for csa in cp.product.csas {
                let csaInfo = ["id": csa.id, "credits_used": csa.creditsUsed, "quantity": Double(csa.creditsUsed) * cp.product.unitsPerCredit] as [String : Any]
                csaUsed.append(csaInfo as NSDictionary)
            }
            pInfo["csa_used"] = csaUsed
            
            paymentProducts.append(pInfo as NSDictionary)
        }
        return paymentProducts
    }
    
    func updateSum() {
        sum = 0.0
        for p in cartProducts {
            sum += p.sum
        }
        let tax = self.totalTaxSum()
        self.headerView.displaySum(sum, tax: tax)
        tableView.tableHeaderView = headerView
    }
    
    func creditsAvailableForCSA(_ csa: FPCSA) -> Int {
        return FPCustomer.activeCustomer()!.csas.filter {
            return $0.id == csa.id
            }[0].limit
    }
    
    func resetOrder() {
        FPCustomer.setActiveCustomer(nil)
        FPOrder.setActiveOrder(nil)
        resetCart()
    }
    
    func resetCart() {
        if let ac = FPCustomer.activeCustomer() {
            for cp in cartProducts {
                for csa in cp.product.csas {
                    let customerCsa = ac.csas.filter {
                        return $0.id == csa.id
                        }[0]
                    customerCsa.limit += csa.creditsUsed
                    csa.limit += csa.creditsUsed
                }
            }
        }
        applicableBalance = 0.0
        cartProducts = [FPCartProduct]()
        tableView.reloadData()
        updateSum()
        delegate?.cartViewDidReset?(self)
    }
    
    @objc func resetPressed() {
        let av = UIAlertView()
        av.title = "Would you like to reset the cart?"
        av.addButton(withTitle: "Reset cart")
        if FPOrder.activeOrder() != nil {
            av.addButton(withTitle: "Reset order")
        }
        if FPCustomer.activeCustomer() != nil {
            av.addButton(withTitle: "Unassign customer and reset cart")
        }
        av.addButton(withTitle: "Cancel")
        av.delegate = self
        av.show()
    }
    
    @objc func checkoutPressed() {
        delegate?.cartViewDidCheckout?(self)
    }
    
    func cartProductWithProduct(_ product: FPProduct) -> FPCartProduct? {
        var p: FPCartProduct?
        for cartProduct in cartProducts {
            if cartProduct.product.id == product.id {
                p = cartProduct
                break
            }
        }
        return p
    }
    
    func addCartProduct(_ cp: FPCartProduct, updating: Bool) {
        var idx: Int?
        for i in 0 ..< cartProducts.count {
            let cartProduct = cartProducts[i]
            if cartProduct.product.id == cp.product.id {
                idx = i
                break
            }
        }
        if let i = idx {
            if updating {
                cartProducts[i] = cp
            } else {
                let c = cartProducts[i]
                c.quantity += cp.quantity
                c.quantityPaid += cp.quantityPaid
                cartProducts[i] = c
            }
        } else {
            cartProducts.insert(cp, at: 0)
        }
        updateSum()
        tableView.reloadData()
    }
    
    // UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 {
            resetCart()
        } else if buttonIndex == 1 && FPOrder.activeOrder() != nil {
            resetOrder()
        } else if FPCustomer.activeCustomer() != nil && (buttonIndex == 1 || buttonIndex == 2) {
            FPCustomer.setActiveCustomer(nil)
            resetCart()
        }
    }
    
    // UITableView data source and delegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cartProducts.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FPCartCell.heightWithCartProduct(cartProducts[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPCartCell") as! FPCartCell
        cell.delegate = self
        cell.cartProduct = cartProducts[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let cp = cartProducts[indexPath.row]
            self.deleteCartProduct(cp, atIndexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.cartViewDidSelectProduct?(self, p: cartProducts[indexPath.row])
    }
    
    func deleteCartProduct(_ cp: FPCartProduct) {
        if let idx = self.cartProducts.firstIndex(of: cp) {
            self.deleteCartProduct(cp, atIndexPath: IndexPath(row: idx, section: 0))
        }
    }
    
    func deleteCartProduct(_ cp: FPCartProduct, atIndexPath indexPath: IndexPath) {
        if let ac = FPCustomer.activeCustomer() {
            for csa in cp.product.csas {
                let customerCsa = ac.csas.filter {
                    return $0.id == csa.id
                    }[0]
                customerCsa.limit += csa.creditsUsed
                csa.limit += csa.creditsUsed
            }
        }
        cartProducts.remove(at: indexPath.row)
        updateSum()
        tableView.deleteRows(at: [indexPath], with: .fade)
        delegate?.cartViewDidDeleteProduct?(self)
    }
    
    // MARK: - FPCartCellDelegate
    func cartCellDeletePressed(_ cell: FPCartCell) {
        self.deleteCartProduct(cell.cartProduct, atIndexPath: self.tableView.indexPath(for: cell)!)
    }
    
}


@objc protocol FPCartViewDelegate {
    @objc optional func cartViewDidCheckout(_ cartView: FPCartView) -> Void
    @objc optional func cartViewDidDeleteProduct(_ cartView: FPCartView) -> Void
    @objc optional func cartViewDidSelectProduct(_ cartView: FPCartView, p: FPCartProduct) -> Void
    @objc optional func cartViewDidReset(_ cartView: FPCartView) -> Void
}
