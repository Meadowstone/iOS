//
//  FPCSA.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPCSA: NSObject {
    
    var id: Int
    var name: String
    var limit: Int
    var type: String
    var creditsUsed = 0
    override var description: String {
        return "name: \(name), limit: \(limit), id: \(id), type: \(type)"
    }
    
    init(id: Int, name: String, limit: Int, type: String) {
        self.id = id
        self.name = name
        self.limit = limit
        self.type = type
        super.init()
    }
    
}
