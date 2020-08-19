//
//  FPAppDelegate.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/26/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import UserNotifications

let kFPAPNsTokenUserDefaultsKey = "kFPAPNsTokenUserDefaultsKey"


//@UIApplicationMain
class FPAppDelegate: UIApplication, UIApplicationDelegate, UIAlertViewDelegate {
    
//    let maxIdleTime = 60.0 * 3.0
//    let logoutTime = 60.0 * 10.0
//    var idleAlertView: UIAlertView?
//    var idleTimer: NSTimer?
//    var logoutTimer: NSTimer?
//    var timerExceeded: Bool = false
    
    var window: UIWindow?
    
    #if Devbuild
    var devBuildWindow: UIWindow?
    #endif
    
    
    class func instance() -> FPAppDelegate {
        return UIApplication.shared.delegate as! FPAppDelegate
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        print("Hello".count)
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options:[.badge, .alert]) { (granted, error) in
                
            }
        } else {
            let settings = UIUserNotificationSettings(types: [.sound, .alert], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        application.registerForRemoteNotifications()
        
        _ = FPCardFlightManager.sharedInstance
        FPCustomLogger.startLogWrite("===== session started")
        
        // Setup
        application.isIdleTimerDisabled = true
        
        self.setupNavigationBar()
        self.setupObservers()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.makeKeyAndVisible()
        
        var status = FPLoginStatus.loggedOut
        var user = FPUser()
        if let activeUser = FPUser.activeUser() {
            status = FPLoginStatus.loggedIn
            user = activeUser
        }
        self.redirectUser(user, withLoginStatus: status)
        
        #if Devbuild
        addDevBuildLabel(to: window!)
        #endif
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        var token = ""
        for i in 0..<deviceToken.count {
            token = token + String(format: "%02.2hhx", arguments: [deviceToken[i]])
        }
        print(token)
        
        UserDefaults.standard.set(token, forKey: kFPAPNsTokenUserDefaultsKey)
        UserDefaults.standard.synchronize()
        
        FPServer.sharedInstance.syncAPNsToken()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications with error: \(error)")
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    override func supportedInterfaceOrientations(for window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
    
    func redirectUser(_ user: AnyObject?, withLoginStatus status: FPLoginStatus) {
        switch status {
        case .loggedIn:
            var vc: UIViewController!
            if let aUser = user as? FPUser {
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    vc = FPAuthOptionsViewController.authOptionsViewController()
                } else {
                    let farmWorker = FPFarmWorker()
                    farmWorker.id = aUser.id
                    farmWorker.email = aUser.email
                    FPFarmWorker.setActiveWorker(farmWorker)
                    FPMenuViewController.setRootAndDisplay()
                }
            } else if (user as? FPFarmWorker) != nil {
                vc = FPProductsAndCartViewController.productsAndCartViewController()
            }
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                let nc = UINavigationController(rootViewController: vc)
                window!.rootViewController = nc
            }
            
        case .loggedOut:
            FPCardFlightManager.sharedInstance.cardFlightCard = nil
            if user is FPUser {
                FPRetailLocation.removeDefault()
                UserDefaults.standard.removeObject(forKey: FPDatabaseSyncDateStringUserDefaultsKey)
                UserDefaults.standard.synchronize()
                FPFarmWorker.setAllWorkers(nil)
                FPFarmWorker.setActiveWorker(nil)
                FPCustomer.setActiveCustomer(nil)
                FPDataAccessLayer.sharedInstance.deleteAllSyncedCustomers()
                FPProduct.setAllProducts(nil)
                FPProduct.synchronize()
                FPMeasurement.setAllMeasurements(nil)
                FPUser.deleteActiveUser()
                FPServer.sharedInstance.clearCookies()
                window!.rootViewController = FPLoginViewController.loginViewController()
            } else {
                FPOrder.setActiveOrder(nil)
                FPCustomer.setActiveCustomer(nil)
                FPFarmWorker.setActiveWorker(nil)
                let vc = FPAuthOptionsViewController.authOptionsViewController()
                let nc = UINavigationController(rootViewController: vc)
                window!.rootViewController = nc
            }
        }
    }
    
    func customerLoggedOut() {
        // @Cardflight card drop
        FPCardFlightManager.sharedInstance.cardFlightCard = nil
        FPCustomer.setActiveCustomer(nil)
        let vc = FPAuthOptionsViewController.authOptionsViewController()
        let nc = UINavigationController(rootViewController: vc)
        window!.rootViewController = nc
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(FPAppDelegate.userLoginStatusChanged(_:)), name: NSNotification.Name(rawValue: FPUserLoginStatusChanged), object: nil)
    }
    
    func setupNavigationBar() {
        UINavigationBar.appearance().barTintColor = UIColor(red: 109.0 / 255.0, green: 140.0 / 255.0, blue: 83.0 / 255.0, alpha: 1.0)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor : UIColor.white]
    }
    
//    func resetTimers() {
//        timerExceeded = false
//        idleTimer?.invalidate()
//        idleTimer = NSTimer.scheduledTimerWithTimeInterval(maxIdleTime, target: self, selector: "timerOff:", userInfo: nil, repeats: false)
//        logoutTimer?.invalidate()
//        logoutTimer = NSTimer.scheduledTimerWithTimeInterval(logoutTime, target: self, selector: "timerOff:", userInfo: nil, repeats: false)
//    }
    
//    func timerOff(timer: NSTimer?) {
//        if timer === logoutTimer {
//            idleAlertView?.dismissWithClickedButtonIndex(1, animated: false)
//            redirectUser(FPFarmWorker.activeWorker(), withLoginStatus: .LoggedOut)
//        } else {
//            timerExceeded = true
//            var message = ""
//            var btnTitle = ""
//            idleAlertView = UIAlertView()
//            idleAlertView!.alertViewStyle = .SecureTextInput
//            if FPFarmWorker.activeWorker() != nil {
//                message = "Device has been locked due to inactivity. Enter your password to unlock."
//                btnTitle = "Confirm"
//            } else if FPCustomer.activeCustomer() != nil {
//                message = "Enter your PIN code in order to continue shopping. Press \"Cancel\" to stop shopping using this account."
//                btnTitle = "Confirm PIN"
//                idleAlertView!.textFieldAtIndex(0)!.keyboardType = .NumberPad
//            }
//            
//            idleAlertView!.delegate = self
//            idleAlertView!.title = "Session expired!"
//            idleAlertView!.addButtonWithTitle(btnTitle)
//            idleAlertView!.addButtonWithTitle("Cancel")
//            idleAlertView!.show()
//        }
//    }
    
    // UIAlertView delegate
//    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
//        if buttonIndex == 0 {
//            let text = alertView.textFieldAtIndex(0)!.text
//            var pass = true
//            if FPFarmWorker.activeWorker() != nil {
//                pass = text == FPFarmWorker.activeWorker()!.password
//            } else if FPCustomer.activeCustomer() != nil {
//                pass = text == FPCustomer.activeCustomer()!.pin
//            }
//            
//            if pass {
//                timerExceeded = false
//                resetTimers()
//            } else {
//                timerOff(nil)
//            }
//        } else {
//            redirectUser(FPFarmWorker.activeWorker(), withLoginStatus: .LoggedOut)
//        }
//        idleAlertView = nil
//    }
    
    // Observers
    @objc func userLoginStatusChanged(_ note: Notification) {
        let userInfo = note.object as! NSDictionary
        let status = FPLoginStatus(rawValue: (userInfo["status"] as! Int))
        let user = userInfo["user"] as AnyObject
        self.redirectUser(user, withLoginStatus: status!)
    }
    
    //    // UIResponder
    //    override func sendEvent(event: UIEvent) {
    //        super.sendEvent(event)
    //
    //        if event.type == .Touches {
    //            let touches = event.allTouches()
    //            if let touch = touches.anyObject() as? UITouch {
    //                let phase = touch.phase
    //                if phase == .Began || phase == .Ended {
    //                    if (FPCustomer.activeCustomer() || FPFarmWorker.activeWorker()) && !timerExceeded && !idleAlertView {
    //                        resetTimers()
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    #if Devbuild
    private func addDevBuildLabel(to window: UIWindow) {
        let devBuildLabel = UILabel()
        devBuildLabel.text = "DEV"
        devBuildLabel.textColor = .red
        devBuildLabel.alpha = 0.5
        devBuildLabel.font = UIFont(name: "HelveticaNeue", size: 50)
        
        let devBuildViewController = UIViewController()
        devBuildViewController.view.addSubview(devBuildLabel)
        devBuildLabel.translatesAutoresizingMaskIntoConstraints = false
        devBuildViewController.view.addConstraint(NSLayoutConstraint(item: devBuildLabel,
                                                                     attribute: .centerX,
                                                                     relatedBy: .equal,
                                                                     toItem: devBuildLabel.superview,
                                                                     attribute: .centerX,
                                                                     multiplier: 1.0,
                                                                     constant: 0.0))
        devBuildViewController.view.addConstraint(NSLayoutConstraint(item: devBuildLabel,
                                                                     attribute: .bottom,
                                                                     relatedBy: .equal,
                                                                     toItem: devBuildLabel.superview,
                                                                     attribute: .bottom,
                                                                     multiplier: 1.0,
                                                                     constant: 0.0))
        
        devBuildWindow = UIWindow(frame: UIScreen.main.bounds)
        devBuildWindow?.rootViewController = devBuildViewController
        devBuildWindow?.windowLevel = .alert
        devBuildWindow?.isHidden = false
        devBuildWindow?.isUserInteractionEnabled = false
    }
    #endif
}

