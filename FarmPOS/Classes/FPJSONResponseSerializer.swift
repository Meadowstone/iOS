//
//  FPJSONResponseSerializer.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 26/08/2014.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import AFNetworking

class FPJSONResponseSerializer: AFJSONResponseSerializer {
    
    override func responseObject(for response: URLResponse!, data: Data!) throws -> Any {
        #if Debug
            if let s = String(data: data, encoding: .utf8) {
                print(s)
            }
        #endif
        return try super.responseObject(for: response, data: data)
    }
   
}
