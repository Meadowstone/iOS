//
//  FPProductDescriptor.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 7/30/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPProductDescriptor: NSObject {
    
    var productId = -1
    var discountPrice: Double?
    var csas = [FPCSA]()
    override var description: String {
        return "productId: \(productId), csas: \(csas)"
    }

}
