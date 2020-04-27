//
//  FPProductCategory.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPProductCategory : NSObject {
    
    var id: Int
    var name: String
    var tax: FPProductCategoryTax?
    
//    static var i: Int = 0
//    var didSet = false
//    var someTax: FPProductCategoryTax?
//    var dummyTax: FPProductCategoryTax? {
//        if !didSet {
//            FPProductCategory.i++
//            if FPProductCategory.i % 3 == 0 {
//                self.someTax = nil
//            } else if FPProductCategory.i % 3 == 2 {
//                self.someTax = FPProductCategoryTax(id: 1, name: "Some Tax", rate: 9.0)
//            } else {
//                self.someTax = FPProductCategoryTax(id: 2, name: "Another Tax", rate: 9.0)
//            }
//        }
//        self.didSet = true
//        return someTax
//    }
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        super.init()
    }
    
}
