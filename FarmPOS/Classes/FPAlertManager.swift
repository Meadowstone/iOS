//
//  FPAlertManager.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/26/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit

class FPAlertManager {
    
    class func showMessage(_ message: String, withTitle title: String) {
        let alert = UIAlertView()
        alert.title = title
        alert.message = message
        alert.addButton(withTitle: "OK")
        alert.show()
    }
    
}
