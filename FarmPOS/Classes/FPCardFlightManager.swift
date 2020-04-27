//
//  FPCardFlightManager.swift
//  Farm POS
//
//  Created by Vladimir Stepanchenko on 9/5/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import MBProgressHUD

let devApiToken           = "87a1487a1baf7ea5b341f976845ca7cf"
let devAccountToken       = "acc_28e9249a3b2b2eb4"

let prodApiToken          = "cb50440e2beb02274253e7059746171c"
let prodAccountToken      = "acc_ec5c97e135bcab98"

//Singleton instance
var instance: FPCardFlightManager?

enum StatusCode {
    case generic
    case swipeTimedOut
    case readerAttached
    case readerConnecting
    case readerConnected
    case waitingForSwipe
    case readerDisconnected
    case unrecognizedCard
    case recognizedCard
}

class FPCardFlightManager : NSObject, CFTReaderDelegate, CFTPaymentViewDelegate {
    
    var cardFlightCard: CFTCard? {
        didSet {
            if cardFlightCard == nil {
                // Drop to 'reader connected' status when saved CardFlight fingerprint is reset
                if statusCode == .recognizedCard {
                    statusCode = .readerConnected
                    status = "Reader connected"
                }
            }
        }
    }
    
    var cardReader: FPReader!
    var statusCode : StatusCode! = .readerDisconnected
    
    var status: String = "" {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPReaderStatusChangedNotification), object: nil)
        }
    }
    
    class var sharedInstance: FPCardFlightManager {
        if instance == nil {
            instance = FPCardFlightManager.setupInstance()
        }
        return instance!
    }
    
    class func setupInstance() -> FPCardFlightManager {
        print(">> reader instance re-created")
        let instance = FPCardFlightManager()
        CFTSessionManager.sharedInstance().setApiToken(prodApiToken, accountToken: prodAccountToken);
        instance.cardReader = FPReader()
        instance.cardReader.delegate = instance
        return instance
    }
    
    class func resetInstance() -> Void {
        if instance != nil {
            instance!.cardReader.delegate = nil
            instance!.cardReader = nil
            instance = nil
        }
    }
    
    //MARK: -- Cardflight integration methods
    
    func waitForSwipe() {
        self.cardReader.beginSwipe()
        self.statusCode = .waitingForSwipe
        self.status = "Waiting for swipe..."
    }
    
    func cancelSwipe() {
        self.cardReader.cancelTransaction()
    }
    
    func chargeCardWithSum(_ sum: Double, completion: @escaping (_ sumPaid: NSDecimalNumber?, _ transactionToken: String?, _ last4: String?, _ errMsg: String?) -> Void) {
        var hud: MBProgressHUD!
        if ((self.cardFlightCard) != nil) {
            let cleanCentValue : NSDecimalNumber = NSDecimalNumber(string:"\(sum)")
            hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud.removeFromSuperViewOnHide = true
            hud.labelText = "Processing"
            
            let dict = ["amount" : cleanCentValue, "description" : "FarmPOS payment"] as [String : Any]
            
            self.cardFlightCard?.charge(withParameters: dict, success: { (charge) -> Void in
                hud.hide(false)
                completion(cleanCentValue, charge?.referenceID, self.cardFlightCard?.last4, nil)
                }, failure: { (error) -> Void in
                    hud.hide(false)
                    completion(nil, nil, nil, error?.localizedDescription)
            })
        }
    }
    
    func getCardToken() -> String {
        if (self.cardFlightCard != nil) {
            let str : String = "\(self.cardFlightCard!.last4)\(self.cardFlightCard!.name)"
            let utf8str: Data = str.data(using: String.Encoding.utf8)!
            let base64Encoded : String = utf8str.base64EncodedString(options: .init(rawValue: 0))
            return base64Encoded
        }
        return ""
    }
    
    //MARK: Reader delegate
    
    func readerIsAttached() {
        self.statusCode = .readerAttached
        self.status = "Reader attached"
        
        FPCustomLogger.writeLogToFile(">> reader attached")
    }
    
    func readerIsConnecting() {
        self.statusCode = .readerConnecting
        self.status = "Connecting..."
        
        FPCustomLogger.writeLogToFile(">> reader connecting")
    }
    
    func readerIsConnected(_ isConnected: Bool, withError error: Error!) {
        self.statusCode = .readerConnected
        self.status = "Reader connected"
        
        FPCustomLogger.writeLogToFile(">> reader connected")
    }
    
    func readerIsDisconnected() {
        self.statusCode = .readerDisconnected
        self.status = "Reader disconnected"
        // TODO check if necessary
        self.cardFlightCard = nil
        
        FPCustomLogger.writeLogToFile(">> reader disconnected")
    }
    
    func readerSwipeDetected() {
        FPCustomLogger.writeLogToFile(">> swipe detected")
    }
    
    func readerSwipeDidCancel() {
        FPCustomLogger.writeLogToFile(">> swipe did cancel")
    }
    
    func readerBatteryLow() {
        FPCustomLogger.writeLogToFile(">> battery low")
    }
    
    func readerNotDetected() {
        FPCustomLogger.writeLogToFile(">> reader not detected")
    }
    
    func callback(_ parameters: [AnyHashable: Any]!) {
        FPCustomLogger.writeLogToFile(">> internal callback: \(parameters)")
    }
    
    func readerCardResponse(_ card: CFTCard!, withError error: Error!) {
        if (card == nil) {
            if (error != nil) {
                if ((error as NSError).code == 102) {
                    self.statusCode = .swipeTimedOut
                } else {
                    self.statusCode = .readerConnected
                }
                self.status = "Swipe timed out"
            }
        }
        else {
            self.statusCode = .recognizedCard
            self.cardFlightCard = card
            self.status = "Card active"
        }
    }
    
    func transactionResult(_ charge: CFTCharge!, withError error: Error!) {
        ()
    }
    
    //MARK: Manual entry view delegate
    
    func keyedCardResponse(_ card: CFTCard!) {
        if (card != nil) {
            self.cardFlightCard = card
        }
        else {
            self.statusCode = .readerConnected
            self.status = "Unrecognized card"
        }
    }
    
    func readerGenericResponse(_ cardData: String!) {
        self.statusCode = .readerConnected
        self.status = "Unrecognized card"
    }
}
