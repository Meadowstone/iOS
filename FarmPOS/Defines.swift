//
//  Defines.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

let FPColorGreen                            = UIColor(red: 98.0 / 255.0, green: 125.0 / 255.0, blue: 70.0 / 255.0, alpha: 1)
let FPColorDarkGray                         = UIColor(red: 71.0 / 255.0, green: 71.0 / 255.0, blue: 71.0 / 255.0, alpha: 1)
let FPColorRed                              = UIColor(red: 204.0 / 255.0, green: 55.0 / 255.0, blue: 55.0 / 255.0, alpha: 1)
let FPColorPaymentFlowBackground            = UIColor(red: 233.0/255.0, green: 235.0/255.0, blue: 229.0/255.0, alpha: 1)
let FPColorPaymentFlowMessage               = UIColor(red: 71.0/255.0, green: 71.0/255.0, blue: 71.0/255.0, alpha: 1)
let FPColorPaymentFlowPlaceholder           = UIColor(white: 144.0/255.0, alpha: 1)

let popoverWidth: CGFloat = 640.0

enum FPPaymentMethod : Int {
    case cash = 2
    case check
    case payLater
    case giftCard
    case cancelled
    case balance
    case paymentCard
    case terminal
    case venmo
    
    func toString() -> String {
        switch self {
            case .cash:
                return "cash"
            case .check:
                return "check"
            default:
                return ""
        }
    }
}

//MARK: Notifications
let FPPaymentMethodSelectedNotification = "FPPaymentMethodSelectedNotification"
let FPDatabaseSyncStatusChangedNotification = "FPDatabaseSyncStatusChangedNotification"
let FPUserLoginStatusChanged = "FPUserLoginStatusChanged"
let FPTransactionOrOrderProcessingNotification = "FPTransactionOrOrderProcessingNotification"
let FPCustomerAuthenticatedNotification = "FPCustomerAuthenticatedNotification"

//MARK: User Defaults
let FPDatabaseSyncDateUserDefaultsKey = "FPDatabaseSyncDateUserDefaultsKey"
let FPDatabaseSyncDateStringUserDefaultsKey = "FPDatabaseSyncDateStringUserDefaultsKey"
