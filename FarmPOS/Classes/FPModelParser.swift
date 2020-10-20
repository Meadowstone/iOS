//
//  FPModelParser.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/27/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPModelParser {
    
    class func userWithInfo(_ userInfo: NSDictionary) -> FPUser {
        let user = FPUser()
        user.id = userInfo["user_id"] as! Int
        user.email = userInfo["email"] as! String
        user.farmId = userInfo["farm_id"] as! String
        user.defaultStateCode = (userInfo["default_state_code"] as! NSNumber).stringValue
        if let f = userInfo["farm"] as? NSDictionary {
            user.farm = self.farmWithInfo(f)
        }
        return user
    }
    
    class func infoWithUser(_ user: FPUser) -> NSDictionary {
        let info: NSMutableDictionary = ["user_id": user.id, "email": user.email, "default_state_code": Int(user.defaultStateCode)!, "farm_id": user.farmId]
        if let f = user.farm {
            info["farm"] = self.infoWithFarm(f)
        }
        return info
    }
    
    
    class func workerWithInfo(_ workerInfo: NSDictionary) -> FPFarmWorker {
        let worker = FPFarmWorker()
        worker.id = workerInfo["worker_id"] as! Int
        worker.email = workerInfo["email"] as! String
        return worker
    }


    class func infoWithFarmWorker(_ fw: FPFarmWorker) -> NSDictionary {
        return ["worker_id": fw.id, "email": fw.email]
    }


    class func retailLocationWithInfo(_ rli: NSDictionary) -> FPRetailLocation {
      return FPRetailLocation(id: rli["location_id"] as! Int, name: rli["name"] as! String)
    }


    class func infoWithRetailLocation(_ rl: FPRetailLocation) -> NSDictionary {
        return ["location_id": rl.id, "name": rl.name]
    }


    class func productDescriptorWithInfo(_ info: NSDictionary) -> FPProductDescriptor {
        let pd = FPProductDescriptor()
        pd.productId = info["product_id"] as! Int
        pd.discountPrice = info["discount_price"] as? Double
        return pd
    }
    
    class func infoWithProductDescriptor(_ pd: FPProductDescriptor) -> NSDictionary {
        var info = [String: Any]()
        info["product_id"] = pd.productId
        if let discPrice = pd.discountPrice {
            info["discount_price"] = discPrice
        }
        return info as NSDictionary
    }
    
    class func customerManageBalanceOptionWithInfo(_ info: NSDictionary) -> FPCustomerManageBalanceOption {
        return FPCustomerManageBalanceOption(
            price: info["pay_credit"] as? Double ?? 0,
            balanceAdded: info["get_credit"] as? Double ?? 0
        )
    }
    
    class func customerWithInfo(_ customerInfo: NSDictionary) -> FPCustomer {
        let customer = FPCustomer()
        customer.wholesale = customerInfo["wholesale"] as! Bool
        customer.id = customerInfo["client_id"] as! Int
        customer.name = customerInfo["name"] as! String
        customer.balance = customerInfo["balance"] as! Double
        customer.farmBucks = (customerInfo["farm_bucks"] as? Double) != nil ? customerInfo["farm_bucks"] as! Double : 0.00
        customer.hasOverdueBalance = customerInfo["has_overdue_balance"] as! Bool
        customer.email = customerInfo["email"] as! String
        customer.pin = customerInfo["pin"] as! String
        customer.phone = customerInfo["phone"] as! String
        customer.phone = (customer.phone.components(separatedBy: CharacterSet(charactersIn: " -()")) as NSArray).componentsJoined(by: "")
        customer.phoneHome = customerInfo["phone_home"] as? String
        customer.city = customerInfo["city"] as? String
        customer.state = customerInfo["state"] as? String
        customer.zip = customerInfo["zip_code"] as? String
        customer.address = customerInfo["address"] as? String
        if let synchronized = customerInfo["synchronized"] as? Bool {
            customer.synchronized = synchronized
        }
        var pds = [FPProductDescriptor]()
        if let ps = customerInfo["products"] as? [NSDictionary] {
            for info in ps {
                pds.append(self.productDescriptorWithInfo(info))
            }
        }
        customer.productDescriptors = pds
                
        return customer
    }
    
    class func infoWithCustomer(_ c: FPCustomer) -> NSDictionary {
        var info = [String: Any]()
        info["wholesale"] = c.wholesale
        info["client_id"] = c.id
        info["name"] = c.name
        info["balance"] = c.balance
        info["farm_bucks"] = c.farmBucks
        info["email"] = c.email
        info["pin"] = c.pin
        info["phone"] = c.phone
        var productDescriptorsInfo = [NSDictionary]()
        for pd in c.productDescriptors {
            productDescriptorsInfo.append(self.infoWithProductDescriptor(pd))
        }
        info["products"] = productDescriptorsInfo
        info["has_overdue_balance"] = c.hasOverdueBalance
        info["synchronized"] = c.synchronized
        if let phoneHome = c.phoneHome {
            info["phone_home"] = phoneHome
        }
        if let city = c.city {
            info["city"] = city
        }
        if let state = c.state {
            info["state"] = state
        }
        if let zip = c.zip {
            info["zip_code"] = zip
        }
        if let address = c.address {
            info["address"] = address
        }
        
        return info as NSDictionary
    }
    
    class func paymentCardProcessorWithInfo(_ info: NSDictionary) -> FPPaymentCardProcessor {
        return FPPaymentCardProcessor(
            name: info["payment_processor"] as? String ?? "",
            transactionFeePercentage: info["fee"] as? Double ?? 0,
            transactionFeeFixed: info["fixed_per_transaction"] as? Double ?? 0
        )
    }
    
    class func measurementWithInfo(_ mi: NSDictionary) -> FPMeasurement {
        return FPMeasurement(id: mi["id"] as! Int, shortName: mi["short"] as! String, longName: mi["long"] as! String)
    }
    
    class func infoWithMeasurement(_ m: FPMeasurement) -> NSDictionary {
        return ["id": m.id, "short": m.shortName, "long": m.longName]
    }
    
    class func productCategoryWithInfo(_ pci: NSDictionary) -> FPProductCategory {
        let pc = FPProductCategory(id: pci["category_id"] as! Int, name: pci["name"] as! String)
        if let taxInfo = pci["tax"] as? NSDictionary {
            pc.tax = self.productCategoryTaxWithInfo(taxInfo)
        }
        return pc
    }
    
    class func infoWithProductCategory(_ pc: FPProductCategory) -> NSDictionary {
        let info: NSMutableDictionary = ["category_id": pc.id, "name": pc.name]
        if let tax = pc.tax {
            info["tax"] = self.infoWithProductCategoryTax(tax)
        }
        return info
    }
    
    class func productCategoryTaxWithInfo(_ info: NSDictionary) -> FPProductCategoryTax? {
        if info.count == 0 {
            return nil
        }
        return FPProductCategoryTax(id: info["id"] as! Int, name: info["name"] as! String, rate: info["rate"] as! Double)
    }
    
    class func infoWithProductCategoryTax(_ object: FPProductCategoryTax) -> NSDictionary {
        return ["id": object.id, "name": object.name, "rate": object.rate]
    }
    
    class func productWithInfo(_ pi: NSDictionary) -> FPProduct {
        let product = FPProduct()
        product.id = pi["product_id"] as! Int
        product.notes = pi["notes"] as? String
        if let r = pi["rental"] as? Bool {
            product.rental = r
        }
        if let forbidAnonymousPurchase = pi["forbid_anonymous_purchase"] as? Bool {
            product.forbidAnonymousPurchase = forbidAnonymousPurchase
        }
        if let hidden = pi["hidden"] as? Bool {
            product.hidden = hidden
        }
        if let trackInventory = pi["track_inventory"] as? Bool {
            product.trackInventory = trackInventory
        }
        if let triggerAmount = pi["trigger_amount"] as? Double {
            product.triggerAmount = triggerAmount
        }
        if let barcodeValue = pi["barcode_value"] as? String {
            product.barcodeValue = barcodeValue
        }
        if let bought = pi["bought"] as? Double {
            product.bought = bought
        }
        if let remaining = pi["remaining"] as? Double {
            product.remaining = remaining
        }
        if let sold = pi["sold"] as? Double {
            product.sold = sold
        }
        product.searchId = pi["search_id"] as? String
        product.price = FPCurrencyFormatter.roundCrrency((pi["price"] as! Double))
        product.discountPrice = product.price
        product.unitsPerCredit = pi["units_per_credit"] as! Double
        if let tm = pi["thumbnail"] as? String {
            product.thumbURL = URL(string: tm)
        }
        if let img = pi["image"] as? String {
            product.imageURL = URL(string: img)
        }
        product.name = pi["name"] as! String
        if let b = pi["wholesale"] as? Bool {
            product.wholesale = b
        }
        product.onSaleNow = pi["on_sale_now"] as! Bool
        product.measurement = self.measurementWithInfo(pi["measurement"] as! NSDictionary)
        product.category = self.productCategoryWithInfo(pi["category"] as! NSDictionary)
        
        if let hdp = pi["has_default_price"] as? Bool {
            product.hasDefaultPrice = hdp
        }
        if let gof = pi["grown_on_farm"] as? Bool {
            product.grownOnFarm = gof
        }

        if let ad = pi["available_from"] as? String {
            if (ad as NSString).length > 0 {
                let dateFormatterUTC = DateFormatter()
                dateFormatterUTC.dateFormat = "dd-MM-yyyy'T'HH:mm:ss"
                dateFormatterUTC.timeZone = TimeZone(identifier: "UTC")
                product.availableFrom = dateFormatterUTC.date(from: ad)
            }
        }
        
        if let ps = pi["supplier"] as? NSDictionary {
            product.supplier = self.productSupplierWithInfo(ps)
        }
        
        return product
    }
    
    class func infoWithProduct(_ p: FPProduct) -> NSDictionary {
        var info = [String: Any]()
        info["rental"] = p.rental
        info["wholesale"] = p.wholesale
        info["product_id"] = p.id
        info["price"] = p.price
        info["units_per_credit"] = p.unitsPerCredit
        info["name"] = p.name
        info["on_sale_now"] = p.onSaleNow
        info["measurement"] = self.infoWithMeasurement(p.measurement)
        info["category"] = self.infoWithProductCategory(p.category)
        info["has_default_price"] = p.hasDefaultPrice
        info["grown_on_farm"] = p.grownOnFarm
        info["hidden"] = p.hidden
        info["forbid_anonymous_purchase"] = p.forbidAnonymousPurchase
        info["track_inventory"] = p.trackInventory
        if let triggerAmount = p.triggerAmount {
            info["trigger_amount"] = triggerAmount
        }
        if let barcodeValue = p.barcodeValue {
            info["barcode_value"] = barcodeValue
        }
        
        if let searchId = p.searchId {
            info["search_id"] = searchId
        }
        
        if let notes = p.notes {
            info["notes"] = notes
        }
        
        if let thumb = p.thumbURL {
            info["thumbnail"] = thumb.absoluteString
        }
        
        if let image = p.imageURL {
            info["image"] = image.absoluteString
        }
        
        if let bought = p.bought {
            info["bought"] = bought
        }
        
        if let remaining = p.remaining {
            info["remaining"] = remaining
        }
        
        if let sold = p.sold {
            info["sold"] = sold
        }
        
        if let af = p.availableFrom {
            let df = DateFormatter()
            info["available_from"] = df.string(from: af)
        }
        
        if let ps = p.supplier {
            info["supplier"] = self.infoWithProductSupplier(ps)
        }
        
        return info as NSDictionary
    }
    
    class func inventoryProductHistoryWithInfo(_ info: NSDictionary) -> FPInventoryProductHistory {
        let id = info["id"] as! Int
        let amount = info["amount"] as! Double
        let dateString = info["created_date"] as! String

        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "UTC")
        df.dateFormat = "dd-MM-yyyy'T'HH:mm:ss"
        let dateCreated = df.date(from: dateString)!
        
        return FPInventoryProductHistory(id: id, dateCreated: dateCreated, amount: amount)
    }
    
    class func productSupplierWithInfo(_ info: NSDictionary?) -> FPProductSupplier? {
        if info == nil || info?.count == 0 {
            return nil
        }
        let id = info!["id"] as! Int
        let contactName = info!["contact_name"] as? String
        let companyName = info!["company_name"] as? String
        return FPProductSupplier(id: id, companyName: companyName, contactName: contactName)
    }
    
    class func infoWithProductSupplier(_ obj: FPProductSupplier) -> NSDictionary {
        var info: [AnyHashable: Any] = ["id": obj.id]
        if let c = obj.contactName {
            info["contact_name"] = c
        }
        if let c = obj.companyName {
            info["company_name"] = c
        }
        return info as NSDictionary
    }
    
    class func giftCardWithInfo(_ info: NSDictionary) -> FPGiftCard {
        return FPGiftCard(id: info["gift_card_id"] as! Int, sum: info["sum"] as! Double)
    }
    
    class func orderWithInfo(_ info: NSDictionary) -> FPOrder {
        let order = FPOrder()
        order.id = info["purchase_id"] as! Int
        order.shippingOption = FPOrder.ShippingOption(rawValue: (info["shipping_option"] as! Int))!
        order.isPaid = info["is_paid"] as! Bool
        order.address = info["address"] as! String
        order.city = info["city"] as! String
        order.state = info["state"] as! String
        order.zipCode = info["zip_code"] as! String
        order.customer = self.customerWithInfo(info["client"] as! NSDictionary)
        order.cartProductsInfo = info["products"] as? [NSDictionary]
        
        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "UTC")
        df.dateFormat = "dd-MM-yyyy'T'HH:mm:ss"
        order.dueDate = df.date(from: info["delivery_date"] as! String)
        
        return order
    }
    
    class func transactionWithInfo(_ info: NSDictionary) -> FPTransaction {
        let t = FPTransaction()
        t.id = info["id"] as! Int
        t.isOrdered = info["is_ordered"] as! Bool
        t.sum = info["sum"] as! Double
        t.customer = self.customerWithInfo(info["client"] as! NSDictionary)
        if let rlc = info["retail_location"] as? NSDictionary {
            t.retailLocation = self.retailLocationWithInfo(rlc)
        }
        if let voided = info["is_voided"] as? Bool {
            t.voided = voided
        }
        if let last4 = info["last_4"] as? String {
            t.last4 = last4
        }
        var pt = FPTransaction.PaymentType(rawValue: info["payment_type"] as! Int)
        if pt == nil {
            pt = FPTransaction.PaymentType.unknown
        }
        t.paymentType = pt!
        
        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "UTC")
        df.dateFormat = "dd-MM-yyyy'T'HH:mm:ss"
        t.paymentDate = df.date(from: info["payment_date"] as! String)
        
        return t
    }
    
    class func farmWithInfo(_ info: NSDictionary) -> FPFarm {
        let farm = FPFarm()
        if let allowCustomerBalancePayments = info["allow_customer_balance_payments"] as? Bool {
            farm.allowCustomerBalancePayments = allowCustomerBalancePayments
        }
        farm.name = info["name"] as! String
        farm.address = info["address"] as! String
        farm.city = info["city"] as! String
        farm.state = info["state"] as! String
        farm.zipCode = info["zip_code"] as! String
        
        if let paymentCardProcessorInfos = info["credit_cards"] as? [NSDictionary],
            let paymentCardProcessorInfo = paymentCardProcessorInfos.first
        {
            farm.paymentCardProcessor = paymentCardProcessorWithInfo(paymentCardProcessorInfo)
        }
        
        if let customerManageBalanceOptionsInfo = info["farm_bucks_credit"] as? [NSDictionary] {
            farm.customerManageBalanceOptions = customerManageBalanceOptionsInfo.map { info in
                customerManageBalanceOptionWithInfo(info)
            }
        }
        
        return farm
    }
    
    class func infoWithFarm(_ farm: FPFarm) -> NSDictionary {
        return ["name": farm.name, "address": farm.address, "city": farm.city, "state": farm.state, "zip_code": farm.zipCode, "allow_customer_balance_payments": farm.allowCustomerBalancePayments]
    }
    
}
