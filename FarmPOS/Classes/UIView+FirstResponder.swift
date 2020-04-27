//
//  UIView+FirstResponder.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/30/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension UIView {
    
    func findFirstResponder() -> UIView? {
        if self.isFirstResponder {
            return self
        }
        for subview in self.subviews {
            let responder = subview.findFirstResponder()
            if responder != nil {
                return responder
            }
        }
        return nil
    }
    
    func lastViewIgnoringViews(_ ignoreViews: Array<UIView>?) -> UIView? {
        var lastView: UIView?
        for subview in self.subviews {
            let shouldIgnoreSubview = ignoreViews?.filter({ return $0 == subview }).count > 0
            if shouldIgnoreSubview || subview.isHidden || subview.alpha == 0 {
                continue
            } else if lastView == nil {
                lastView = subview
            } else if subview.frame.maxY > lastView!.frame.maxY {
                lastView = subview
            }
        }
        return lastView
    }
    
    func lastView() -> UIView? {
        return self.lastViewIgnoringViews(nil)
    }
    
}
