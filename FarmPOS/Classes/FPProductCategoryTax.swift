//
//  FPProductCategoryTax.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 14/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPProductCategoryTax: NSObject {
    
    var id: Int
    var name: String
    var rate: Double
    
    init(id: Int, name: String, rate: Double) {
        self.id = id
        self.name = name
        self.rate = rate
        super.init()
    }
    
}
