//
//  FPInputValidator.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation

class FPInputValidator: NSObject {
    
    class func preprocessCurrencyText(_ t: String, relativeTo tt: String) -> String {
        var text = t
        let ttext = tt
        if (ttext as NSString).length == 0 && text == "." {
            text = "0."
        } else if ttext == "0" {
            text = "." + text
        }
        return (text as NSString).replacingOccurrences(of: "..", with: ".") // for iphone
    }
    
    class func shouldAddString(_ string: String, toString: String, maxInputCount: Int, isDecimal: Bool) -> Bool {
        let resultString = toString + string
        if (string as NSString).length == 0 {
            return true
        } else if (resultString as NSString).length > maxInputCount {
            return false
        } else if string == "." && (toString as NSString).range(of: ".").length != 0 {
            return false
        }
        
        let maxDigitsAfterDecimal = 2
        if (resultString as NSString).range(of: ".").length > 0 && (resultString as NSString).length - (resultString as NSString).range(of: ".").location - 1 > maxDigitsAfterDecimal {
            return false
        }
        
        
        return true
    }
    
    class func textAfterValidatingCurrencyText(_ currencyText: String) -> String {
        var resultText = ""
        if (currencyText as NSString).length > 0 {
            let text = (currencyText as NSString).substring(from: (currencyText as NSString).length - 1)
            resultText = (currencyText as NSString).substring(to: (currencyText as NSString).length - 1)
            let t = FPInputValidator.preprocessCurrencyText(text, relativeTo: resultText)
            if FPInputValidator.shouldAddString(t, toString: resultText, maxInputCount: Int.max, isDecimal: true) {
                resultText = resultText + t
            }
        }
        return resultText
    }
    
}
