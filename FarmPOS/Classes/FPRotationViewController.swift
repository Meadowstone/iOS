//
//  FPRotationViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 25/08/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPRotationViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if isPad {
            return UIInterfaceOrientationMask.landscape
        } else {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
}

class FPRotationTableViewController: UITableViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if isPad {
            return UIInterfaceOrientationMask.landscape
        } else {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
}

extension UINavigationController {
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        if isPad {
            return UIInterfaceOrientationMask.landscape
        } else {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
}
