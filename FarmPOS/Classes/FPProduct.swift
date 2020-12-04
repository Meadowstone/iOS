//
//  FPProduct.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit

var _allProducts: [FPProduct]?
class FPProduct: NSObject {
    
    var bought: Double?
    var remaining: Double?
    var sold: Double?
    var orderDiscount: Double?
    @objc var barcodeValue: String?
    var triggerAmount: Double?
    var trackInventory = false
    var id = 0
    var notes: String?
    var rental = false
    @objc var searchId: String?
    var hasDefaultPrice = true
    var grownOnFarm = false
    var forbidAnonymousPurchase = false
    var hidden = false
    var price = 0.0
    var discountPrice = 0.0
    @objc var name = ""
    var unitsPerCredit = 0.0
    var category: FPProductCategory!
    var measurement: FPMeasurement!
    var availableFrom: Date?
    @objc var onSaleNow: Bool = true
    var wholesale: Bool = false
    var imageURL: URL?
    var thumbURL: URL?
    var supplier: FPProductSupplier?
    
    var actualPrice: Double {
        let p = min(price, discountPrice)
        return FPCurrencyFormatter.roundCrrency(p)
    }
    
    var pureTaxValue: Double {
        var ptv = 0.0
        if let tax = self.category.tax {
            ptv = FPCurrencyFormatter.roundCrrency((self.actualPrice / 100.0) * tax.rate)
        }
        return ptv
    }
    
    var baseTaxValue: Double {
        var ptv = 0.0
        if let tax = self.category.tax {
            ptv = FPCurrencyFormatter.roundCrrency((self.price / 100.0) * tax.rate)
        }
        return ptv
    }
    
    var actualPriceWithTax: Double {
        return self.actualPrice + self.pureTaxValue
    }
    
    var hasDiscount: Bool {
        return price > actualPrice
    }
    
    override var description: String { return "Id: \(id). Name: \(name)." }
    
    
    func mergeWithProduct(_ product: FPProduct) {
        self.name = product.name
        self.hidden = product.hidden
        self.searchId = product.searchId
        self.imageURL = product.imageURL
        self.price = product.price
        self.category = product.category
        self.onSaleNow = product.onSaleNow
        self.availableFrom = product.availableFrom
        self.measurement = product.measurement
        self.supplier = product.supplier
        self.trackInventory = product.trackInventory
        self.barcodeValue = product.barcodeValue
        self.triggerAmount = product.triggerAmount
        self.bought = product.bought
        self.remaining = product.remaining
        self.sold = product.sold
    }
    
    class func storagePath() -> String {
        let documents = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] 
        let path = "\(documents)/products.dat"
        return path
    }
    
    class func allProducts() -> [FPProduct]? {
        if _allProducts == nil {
            _allProducts = self.cachedProducts()
        }
        let fProducts = _allProducts?.filter({ (product) -> Bool in
            return UIDevice.current.userInterfaceIdiom == .phone || (UIDevice.current.userInterfaceIdiom == .pad && !product.hidden)
        })
        if let c = FPCustomer.activeCustomer() {
            if c.wholesale {
                return fProducts
            }
        }
        return fProducts?.filter({ (product) -> Bool in
            var shouldReturn = !product.wholesale
            if FPCustomer.activeCustomer() == nil {
                shouldReturn = shouldReturn && !product.forbidAnonymousPurchase
            }
            return shouldReturn
        })
    }
    
    class func products() -> [FPProduct]? {
        if _allProducts == nil {
            _allProducts = self.cachedProducts()
        }
        return _allProducts
    }
    
    class func reloadAllProducts() {
        _allProducts = self.cachedProducts()
    }
    
    class func setAllProducts(_ products: Array<FPProduct>?) {
        _allProducts = products
    }
    
    class func cachedProducts() -> [FPProduct]? {
        if !FileManager.default.fileExists(atPath: self.storagePath()) {
            return nil
        }
        
        if let productsDicts = NSKeyedUnarchiver.unarchiveObject(withFile: self.storagePath()) as? [NSDictionary] {
            var cachedProducts = [FPProduct]()
            for info in productsDicts {
                cachedProducts.append(FPModelParser.productWithInfo(info))
            }
            return cachedProducts
        } else {
            FPAlertManager.showMessage("Critical error on performing a cache fetch. Please perform a Sync operation. If that doesn't help, make a clean app install.", withTitle: "Critical Error")
            return nil
        }
    }
    
    class func synchronize() {
        self.resetAllProducts()
        if let allItems = _allProducts {
            var storeInfo = [NSDictionary]()
            for item in allItems {
                storeInfo.append(FPModelParser.infoWithProduct(item))
            }
            NSKeyedArchiver.archiveRootObject(storeInfo, toFile: self.storagePath())
        } else {
            if FileManager.default.fileExists(atPath: self.storagePath()) {
                try! FileManager.default.removeItem(atPath: self.storagePath())
            }
        }
    }
    
    class func resetAllProducts() {
        if let products = _allProducts {
            for product in products {
                if !product.hasDefaultPrice {
                    product.price = 0.00
                }
                product.orderDiscount = nil
                product.discountPrice = product.price
            }
            FPProduct.setAllProducts(products)
        }
    }
    
    class func addDiscounts(using productDescriptors: [FPProductDescriptor]) {
        guard let products = FPProduct.allProducts() else { return }
        for productDescriptor in productDescriptors {
            guard let discountPrice = productDescriptor.discountPrice else { continue }
            guard let product = products
                .filter({ $0.id == productDescriptor.productId })
                .first else { continue }
            product.discountPrice = discountPrice
            FPProduct.setAllProducts(products)
        }
    }
    
}
