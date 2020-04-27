//
//  FPInventoryProductNote.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 23/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPInventoryProductNote: NSObject {
    
    var id: Int
    var text: String
    
    init (id: Int, text: String) {
        self.id = id
        self.text = text
        super.init()
    }
    
}
