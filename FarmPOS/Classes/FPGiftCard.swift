//
//  FPGiftCard.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPGiftCard : NSObject {
    
    var id: Int
    var sum: Double
    
    init(id: Int, sum: Double) {
        self.id = id
        self.sum = sum
        super.init()
    }
    
}
