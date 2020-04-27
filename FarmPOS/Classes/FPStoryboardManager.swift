//
//  FPStoryboardManager.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/27/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit

class FPStoryboardManager {
    
    class func loginStoryboard() -> UIStoryboard {
        var name = "Login"
        if UIDevice.current.userInterfaceIdiom == .pad {
            name += "-iPad"
        }
        return UIStoryboard(name: name, bundle: nil)
    }
    
    class func productsAndCartStoryboard() -> UIStoryboard {
        var name = "ProductsAndCart"
        if UIDevice.current.userInterfaceIdiom == .pad {
            name += "-iPad"
        }
        return UIStoryboard(name: name, bundle: nil)
    }
    
}
