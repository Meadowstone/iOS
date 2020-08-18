//
//  FPServer.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/26/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import AFNetworking

let kInternalError = "Internal server error"

var kHost = ""

// Caching related
let kCustomersWorkersProducts = "customers_workers_products/"
//let kCustomersWorkersProducts = "customers_workers_products_2/"
let kHasUpdates = "has_db_updates/"

// Login & Auth
let kLogin = "login/"
let kFarmWorkerAuth = "worker_auth/"
let kCustomerAuth = "customer_auth/"
let kFarmWorkerEmails = "farm_worker_emails/"

// Cutomers
let kCustomerCreate         = "client_create/"
let kCustomerEdit           = "client_edit/"
let kCreditCards            = "client_credit_card_list/"
let kCreditCardCreate       = "client_credit_card_create/"
let kCreditCardDelete       = "client_credit_card_delete/"
let kCreditCardMakeDefault  = "client_credit_card_make_default/"
let kClientSendPurchaseHistory = "send_client_purchase_history/"
let kBalanceDeposit         = "balance_deposit/"
let kCustomers              = "clients/"
let kSuppliers              = "suppliers/"
let kAPNSTokenAdd           = "apns_token_add/"

// Products
let kProducts           = "products/"
let kProductEdit        = "product_edit/"
let kProductCreate      = "product_create/"
let kProductCategories  = "product_categories/"
let kOrders             = "unfulfilled_orders/"
let kOrderCancel        = "unfulfilled_order_cancel/"
let kTransactions       = "payments/"
let kVoidTransaction    = "void_transaction/"
let kTransactionReceipt = "transaction_receipt/"
let kPaymentProcess     = "payment_process/"
let kNotesAdd           = "product_note_create/"
let kNotesDelete        = "product_note_delete/"
let kProductNotes       = "product_note_display/"
let kInventoryAdd       = "product_inventory_add/"
let kTriggerAlerts      = "trigger_alerts/"
var kInventoryHistory   = "inventory_history/"
var kInventoryHistoryDelete   = "inventory_history_delete/"

// Gift Cards
let kGiftCards        = "gift_cards_info/"
let kGiftCardPurchase = "gift_card_purchase/"
let kGiftCardRedeem   = "gift_card_redeem/"

// Cardflight
let kCreateCardFlightToken = "create_cardflight_token/"
let kCardflightLogin       = "cardflight_login/"

// Farm
let kCashCheckSummary = "cash_check_summary/"
let kCashCheckSummarySet = "cash_check_summary_set/"


class FPServer : AFHTTPSessionManager {
    
    var progress: ((Double) -> Void)!
    var syncDataTask: URLSessionDataTask?
    var allowedToSyncPayments: Bool = false
    var syncing: Bool = false
    var syncingDatabase: Bool = false
    var inventoryEnabled: Bool = false
    
    // Updates
    var hasUpdates: Bool = false {
        didSet {
            if hasUpdates {
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
            }
        }
    }
    var updatesTimer: Timer?
    
    class var sharedInstance: FPServer {
        struct Static {
            static let instance = FPServer.setupInstance()
        }
        return Static.instance
    }
    
    class func setupInstance() -> FPServer {
        #if Devbuild
            kHost = "https://dev.farmstandcart.com/pos/api"
            #else
            kHost = "http://farmstand.skihearthfarm.com/pos/api"
        #endif
        let instance = FPServer(baseURL: URL(string: kHost))
        instance?.requestSerializer.timeoutInterval = 60.0
        instance?.responseSerializer = FPJSONResponseSerializer(readingOptions: .allowFragments)
        instance?.reachabilityManager.setReachabilityStatusChange { status in
            if status == AFNetworkReachabilityStatus.reachableViaWiFi || status == AFNetworkReachabilityStatus.reachableViaWWAN {
                instance?.startMonitoringChanges()
            } else {
                instance?.stopMonitoringChanges()
            }
        }
        instance?.reachabilityManager.startMonitoring()
        return instance!
    }
    
    func syncAPNsToken() {
        if let token = UserDefaults.standard.object(forKey: kFPAPNsTokenUserDefaultsKey) as? String {
            var devBuild = false
            #if Debug
                devBuild = true
            #endif
            let params = ["token": token, "is_dev": devBuild] as [String : Any]
            self.post(kAPNSTokenAdd, parameters: params, success: nil, failure: nil)
        }
    }
    
    func startMonitoringChanges() {
        updatesTimer = Timer.scheduledTimer(timeInterval: 20.0, target: self, selector: #selector(FPServer.triggerUpdates), userInfo: nil, repeats: true)
    }
    
    func stopMonitoringChanges() {
        updatesTimer?.invalidate()
        updatesTimer = nil
    }
    
    @objc func triggerUpdates() {
        self.checkUpdates(nil)
    }
    
    func checkUpdates(_ completion: ((_ hasUpdates: Bool) -> Void)? = nil) {
        if let syncDate = UserDefaults.standard.object(forKey: FPDatabaseSyncDateStringUserDefaultsKey) as? String {
            
            self.get(kHasUpdates, parameters: ["date": syncDate], success: { (dataTask, responseObject) -> Void in
                if let r = responseObject as? NSDictionary {
                    if let b = r["has_updates"] as? Bool {
                        self.hasUpdates = b
                    }
                    completion?(self.hasUpdates)
                }
            }, failure: { (dataTask, error) -> Void in
                completion?(self.hasUpdates)
            })
        } else {
            self.hasUpdates = true
            completion?(self.hasUpdates)
        }
    }
    
    func clearCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies(for: self.baseURL) {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
    
    func errors(_ errors: Any?) -> String? {
        var errMsg: String?
        if let err = errors as? Dictionary<String, NSArray> {
            errMsg = ""
            for (key, value) in err {
                let components = value.componentsJoined(by: " ")
                errMsg = errMsg! + "\(key): \(components)\n"
            }
        } else if let err = errors as? NSError {
            if self.reachabilityManager.isReachable == false {
                errMsg = "Host isn't reachable. Please make sure you have an active Internet connection and try again later."
            } else {
                errMsg = err.localizedDescription
            }
        } else if let err = errors as? String {
            if err == "Operation requires authorized access." {
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPUserLoginStatusChanged), object: ["status": FPLoginStatus.loggedOut.rawValue, "user": FPUser()])
            }
            errMsg = err
        }
        return errMsg
    }
    
    func syncPaymentsIfNeededCompletion(_ completion:((_ errMsg: String?) -> Void)?, progress: @escaping (_ p: Double) -> Void) -> Bool {
        var result = false
        if !syncing && FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() {
            syncing = true
            result = true
            
            self.progress = progress
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
            
            let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
                self.removeObserversAndReleaseSyncTask()
                var errors: String? = kInternalError
                if let r = responseObject as? NSDictionary {
                    if r["status"] as! Bool {
                        FPDataAccessLayer.sharedInstance.deleteAllPurchases()
                        self.syncDatabaseWithInfo(r)
                    }
                    errors = self.errors(r["errors"])
                }
                self.syncing = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
                completion?(errors)
            }
            
            let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
                self.removeObserversAndReleaseSyncTask()
                self.syncing = false
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
                completion?(self.errors(error))
            }
            
            var p = Dictionary<String, Any>()
            let data = try! JSONSerialization.data(withJSONObject: FPDataAccessLayer.sharedInstance.allPurchasesInfo(), options: .init(rawValue: 0))
            p["payments"] = String(data: data, encoding: .utf8)!
            self.requestSerializer.timeoutInterval = 300.0
            self.removeObserversAndReleaseSyncTask()
            self.syncDataTask = self.post(kPaymentProcess, parameters: p, success: success, failure: failure)
            self.syncDataTask!.addObserver(self, forKeyPath: "countOfBytesExpectedToReceive", options: .new, context: nil)
            self.syncDataTask!.addObserver(self, forKeyPath: "countOfBytesReceived", options: .new, context: nil)
            self.requestSerializer.timeoutInterval = 60.0
        }
        return result
    }
    
    func removeObserversAndReleaseSyncTask() {
        self.syncDataTask?.removeObserver(self, forKeyPath: "countOfBytesReceived")
        self.syncDataTask?.removeObserver(self, forKeyPath: "countOfBytesExpectedToReceive")
        self.syncDataTask = nil
    }
    
    func syncCustomersIfNeededCompletion(_ completion: @escaping (_ errMsg: String?) -> Void) -> Bool {
        var result = false
        if !syncing && FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() {
            syncing = true
            result = true
            
            let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
                var errors: String? = kInternalError
                self.syncing = false
                if let r = responseObject as? NSDictionary {
                    if r["status"] as! Bool {
                        FPDataAccessLayer.sharedInstance.updateCustomersAndPurchasesWithCustomers(r["clients"] as! [NSDictionary])
                    }
                    errors = self.errors(r["errors"])
                }
                completion(errors)
            }
            
            let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
                self.syncing = false
                completion(self.errors(error))
            }
            
            
            var dicts = [NSDictionary]()
            for customer in FPDataAccessLayer.sharedInstance.unsyncedCustomers() {
                dicts.append(FPDataAccessLayer.sharedInstance.infoWithCustomer(customer))
            }
            
            let data = try! JSONSerialization.data(withJSONObject: dicts, options: .init(rawValue: 0))
            var params = [String: Any]()
            params["clients"] = String(data: data, encoding: .utf8)
            self.post(kCustomerCreate, parameters: params, success: success, failure: failure)
        }
        return result
    }
    
    //MARK: - Caching related
    func syncWorkersCustomersProductsMeasurementsWithProgress(_ progress: @escaping (_ p: Double) -> Void, completion: @escaping (_ errMsg: String?) -> Void) {
        
        self.progress = progress
        NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
        
        self.syncingDatabase = true
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            self.removeObserversAndReleaseSyncTask()
            var errors: String? = kInternalError
            self.syncingDatabase = false
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    self.syncDatabaseWithInfo(r)
                }
                errors = self.errors(r["errors"])
            }
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            self.removeObserversAndReleaseSyncTask()
            self.syncingDatabase = false
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
            let errors = self.errors(error)
            completion(errors)
        }
        self.requestSerializer.timeoutInterval = 300.0
        self.removeObserversAndReleaseSyncTask()
        self.syncDataTask = self.get(kCustomersWorkersProducts, parameters: nil, success: success, failure: failure)
        self.syncDataTask!.addObserver(self, forKeyPath: "countOfBytesExpectedToReceive", options: .new, context: nil)
        self.syncDataTask!.addObserver(self, forKeyPath: "countOfBytesReceived", options: .new, context: nil)
        self.requestSerializer.timeoutInterval = 60.0
    }
    
    func syncDatabaseWithInfo(_ r: NSDictionary) {

        // Measurements
        var measurements: Array<FPMeasurement> = []
        if let mRaw = r["measurements"] as? Array<Dictionary<String, AnyObject>> {
            for mi in mRaw {
                measurements.append(FPModelParser.measurementWithInfo(mi as NSDictionary))
            }
        }
        FPMeasurement.setAllMeasurements(measurements)
        

        // Products
        var products: Array<FPProduct> = []
        for pi in r["products"] as! Array<NSDictionary> {
            products.append(FPModelParser.productWithInfo(pi))
        }
        FPProduct.setAllProducts(products)
        
        // -- Product Discounts for days
        if let dayDiscounts = r["day_discounts"] as? [NSDictionary] {
            for discounts in dayDiscounts {
                let day = (discounts["day"] as! NSNumber).intValue + 1
                for info in discounts["products"] as! [NSDictionary] {
                    let infoCopy = info.mutableCopy() as! NSMutableDictionary
                    infoCopy["day"] = day
                    let d = FPModelParser.productDiscountWithInfo(infoCopy)
                    let filteredProducts = FPProduct.products()?.filter({ (product) -> Bool in
                        return product.id == d.productId
                    })
                    if let products = filteredProducts, products.count > 0 {
                        let product = products[0]
                        product.dayDiscounts.append(d)
                    }
                }
            }
        }
        
        FPProduct.synchronize()
        
        // Customers
        FPDataAccessLayer.sharedInstance.persistCustomers(r["clients"] as! [NSDictionary])
        
        // Farm Workers
        var workers: Array<FPFarmWorker> = []
        for info in r["workers"] as! Array<NSDictionary> {
            workers.append(FPModelParser.workerWithInfo(info))
        }
        FPFarmWorker.setAllWorkers(workers)
        
        // Retail Locations
        var retailLocations: Array<FPRetailLocation> = []
        if let rlRaw = r["retail_locations"] as? Array<Dictionary<String, AnyObject>> {
            for rli in rlRaw {
                retailLocations.append(FPModelParser.retailLocationWithInfo(rli as NSDictionary))
            }
        }
        FPRetailLocation.setAllRetailLocations(retailLocations)
        
        if let farm = r["farm_info"] as? NSDictionary {
            FPUser.activeUser()?.farm = FPModelParser.farmWithInfo(farm)
            FPUser.save(FPUser.activeUser()!)
        }
        
        if let date = r["date"] as? String {
            let dateFormatterUTC = DateFormatter()
            dateFormatterUTC.dateFormat = "dd-MM-yyyy'T'HH:mm:ss"
            dateFormatterUTC.timeZone = TimeZone(identifier: "UTC")
            let d = dateFormatterUTC.date(from: date)
            
            UserDefaults.standard.set(d, forKey: FPDatabaseSyncDateUserDefaultsKey)
            UserDefaults.standard.set(date, forKey: FPDatabaseSyncDateStringUserDefaultsKey)
            UserDefaults.standard.synchronize()
        }
        
        self.hasUpdates = false
        NotificationCenter.default.post(name: Notification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
    }
    
    
    //MARK: - Login and authentication
    func loginWithFarmID(_ farmID: String, email: String, password: String, completion:@escaping (_ errMsg: String?) -> Void) {
        
        let version = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as NSString as String) as? String
        let params = ["farm_id": farmID, "email": email, "password": password, "version": version]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            var user: FPUser?
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    var userInfo = r["user"] as! Dictionary<String, Any>
                    userInfo["default_state_code"] = r["default_state_code"]
                    user = FPModelParser.userWithInfo(userInfo as NSDictionary)
                    FPUser.save(user!)
                }
                
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
            
            if errors == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPUserLoginStatusChanged), object: ["status": FPLoginStatus.loggedIn.rawValue, "user": user!])
            }
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        
        self.post(kLogin, parameters: params, success: success, failure: failure)
    }
    
    func farmWorkerEmailsCompletion(_ completion:@escaping (_ errMsg: String?, _ emails: NSArray?) -> Void) {
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var emails: NSArray?
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    emails = r["farm_worker_emails"] as? NSArray
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, emails)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            var timedOut = false
            if let e = error {
                timedOut = (e as NSError).code == NSURLErrorTimedOut
            }
            if (!self.reachabilityManager.isReachable || timedOut) {
                if let fws = FPFarmWorker.allWorkers() {
                    var emails = [String]()
                    for fw in fws {
                        emails.append(fw.email)
                    }
                    completion(nil, emails as NSArray?)
                }
            } else {
                let errors = self.errors(error)
                completion(errors, nil)
            }
        }
        
        self.get(kFarmWorkerEmails, parameters: nil, success: success, failure: failure)
    }
    
    func farmWorkerAuthenticateWithEmail(_ email: String, password: String, completion:@escaping (_ errMsg: String?) -> Void) {
        
        let params = ["email": email, "password": password]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                
                if r["status"] as! Bool {
                    let workerInfo = r["worker"] as! Dictionary<String, AnyObject>
                    let worker = FPModelParser.workerWithInfo(workerInfo as NSDictionary)
                    FPFarmWorker.setActiveWorker(worker)
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
            
            if errors == nil {
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPUserLoginStatusChanged), object: ["status": FPLoginStatus.loggedIn.rawValue, "user": FPFarmWorker.activeWorker()!])
            }
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        
        self.post(kFarmWorkerAuth, parameters: params, success: success, failure: failure)
    }
    
    func customerAuthenticateWithPhone(_ phone: String, pin: String, completion:@escaping (_ errMsg: String?, _ customer: FPCustomer?) -> Void) {
        FPCardFlightManager.sharedInstance.cardFlightCard = nil
        if self.reachabilityManager.isReachable {
            var errMsg: String?
            if FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() {
                let sCustomers = FPDataAccessLayer.sharedInstance.unsyncedCustomers().filter({ return $0.phone == phone && $0.pin == $0.pin })
                if sCustomers.count > 0 {
                    errMsg = "This customer has not yet been synchronized with online store. Please synchronize the database to use this customer's account online."
                }
            }
            if FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() {
                if let customer = FPDataAccessLayer.sharedInstance.customerWithPhone(phone, andPin: pin) {
                    if FPDataAccessLayer.sharedInstance.customerHasUnsyncedPurchases(customer) {
                        errMsg = "This customer has purchases that have not yet been synchronized with online store. Please synchronize the database to use this customer's account online."
                    }
                }
            }
            if errMsg != nil {
                completion(errMsg, nil)
                return
            }
        }
        
        let params = ["phone": phone, "pin": pin]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var customer: FPCustomer? = nil
            
            if let r = responseObject as? NSDictionary {
                
                if r["status"] as! Bool {
                    let customerInfo = r["client"] as! Dictionary<String, AnyObject>
                    customer = FPModelParser.customerWithInfo(customerInfo as NSDictionary)
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, customer)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            var timedOut = false
            if let e = error as NSError? {
                timedOut = e.code == NSURLErrorTimedOut
            }
            if (!self.reachabilityManager.isReachable || timedOut) {
                var errMsg: String? = "Phone or pin don't match"
                var customer: FPCustomer?
                if let c = FPDataAccessLayer.sharedInstance.customerWithPhone(phone, andPin: pin) {
                    customer = FPDataAccessLayer.sharedInstance.customerWithCDCustomer(c)
                    errMsg = nil
                }
                completion(errMsg, customer)
            } else {
                let errors = self.errors(error)
                completion(errors, nil)
            }
        }
        
        self.post(kCustomerAuth, parameters: params, success: success, failure: failure)
    }
    
    
    //MARK: - Customers
    func customerCreateWithName(_ name: String, email: String, pin: String, phone: String, phoneHome: String?, state: String?, city: String?, zip: String?, address: String?, completion: @escaping (_ errMsg: String?, _ customer: FPCustomer?) -> Void) {
        
        var params = ["name": name, "email": email, "pin": pin, "phone": phone]
        if let ph = phoneHome {
            params["phone_home"] = ph
        }
        if let s = state {
            params["state"] = s
        }
        if let c = city {
            params["city"] = c
        }
        if let z = zip {
            params["zip_code"] = z
        }
        if let a = address {
            params["address"] = a
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var customer: FPCustomer?
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    let customerInfo = r["client"] as! Dictionary<String, AnyObject>
                    customer = FPModelParser.customerWithInfo(customerInfo as NSDictionary)
                    FPDataAccessLayer.sharedInstance.createCustomerWithInfo(FPModelParser.infoWithCustomer(customer!))
                    FPDataAccessLayer.sharedInstance.save()
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, customer)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            var timedOut = false
            if let e = error as NSError? {
                timedOut = e.code == NSURLErrorTimedOut
            }
            if (!self.reachabilityManager.isReachable || timedOut) {
                var error: String?
                if !NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}").evaluate(with: email) {
                    error = "Enter valid email"
                }
                
                let customers = FPDataAccessLayer.sharedInstance.allCustomers()
                var cs = customers.filter({ $0.phone == phone })
                if cs.count > 0 {
                    error = "Account with this phone already exists"
                }
                cs = customers.filter({ $0.email == email })
                if cs.count > 0 {
                    error = "Account with this email already exists"
                }
                
                if error == nil {
                    let customer = FPCustomer()
                    customer.name = name
                    customer.email = email
                    customer.pin = pin
                    customer.phone = phone
                    customer.phoneHome = phoneHome
                    customer.state = state
                    customer.address = address
                    customer.city = city
                    customer.zip = zip
                    customer.synchronized = false
                    customer.id = FPDataAccessLayer.sharedInstance.usableCustomerId()
                    FPDataAccessLayer.sharedInstance.createCustomerWithInfo(FPModelParser.infoWithCustomer(customer))
                    FPDataAccessLayer.sharedInstance.save()
                    completion(nil, customer)
                } else {
                    completion(error, nil)
                }
            } else {
                let errors = self.errors(error)
                completion(errors, nil)
            }
        }
        
        self.post(kCustomerCreate, parameters: params, success: success, failure: failure)
    }
    
    func customerEdit(customer: FPCustomer, _ name: String, email: String, phone: String, pin: String, completion:@escaping (_ errMsg: String?, _ customer: FPCustomer?) -> Void) {
        
        let params = ["id": customer.id, "name": name, "email": email, "phone": phone, "pin": pin] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var aCustomer: FPCustomer?
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    let customerInfo = r["client"] as! Dictionary<String, AnyObject>
                    aCustomer = FPModelParser.customerWithInfo(customerInfo as NSDictionary)
                    FPDataAccessLayer.sharedInstance.saveCustomer(aCustomer!, searchByID: true)
                    FPDataAccessLayer.sharedInstance.save()
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, aCustomer)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        
        self.post(kCustomerEdit, parameters: params, success: success, failure: failure)
    }
    
    func creditCardsWithCompletion(_ countOnly: Bool, completion: @escaping (_ errMsg: String?, _ cards: Array<FPCreditCard>?, _ count : Int?) -> Void) {
        var params = ["client_id": FPCustomer.activeCustomer()!.id]
        
        if countOnly {
            params["get_card_count_only"] = 1
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var creditCards = [FPCreditCard]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    // Process cards
                    if !countOnly {
                        for info in r["card_list"] as! Array<NSDictionary> {
                            creditCards.append(FPModelParser.creditCardWithInfo(info))
                        }
                    } else {
                        completion(nil, nil, r["card_count"] as? Int)
                        return
                    }
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, creditCards, nil)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil, nil)
        }
        self.get(kCreditCards, parameters: params, success: success, failure: failure)
    }
    
    func creditCardCreateWithCardNumber(_ cardNumber: String, expirationDate: String, cvv: String, label: String, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["client_id": FPCustomer.activeCustomer()!.id, "card_number": cardNumber, "expiration_date": expirationDate, "cvv": cvv, "label": label] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kCreditCardCreate, parameters: params, success: success, failure: failure)
    }
    
    func creditCardDelete(_ creditCard: FPCreditCard, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["token": creditCard.token]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kCreditCardDelete, parameters: params, success: success, failure: failure)
    }
    
    func creditCardMakeDefault(_ card: FPCreditCard, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["token": card.token]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kCreditCardMakeDefault, parameters: params, success: success, failure: failure)
    }
    
    func balanceDepositWithSum(_ sum: Double, isCheck: Bool, useCreditCard: Bool, checkNumber: String?, transactionToken: String?, last4: String?, completion:@escaping (_ errMsg: String?) -> Void) {
        let params: NSMutableDictionary = ["sum": sum, "is_check": isCheck, "use_credit_card": useCreditCard, "client_id": FPCustomer.activeCustomer()!.id, "check_number": checkNumber != nil ? checkNumber! : ""]
        if let tt = transactionToken {
            params["transaction_token"] = tt
        }
        if let l4 = last4 {
            params["last_4"] = l4
        }
        if let location = FPRetailLocation.defaultLocation() {
            params["location_id"] =  location.id
        }
        // Add worker ID info (MW-85)
        if let worker = FPFarmWorker.activeWorker() {
            params["worker_id"] = worker.id
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
                if r["status"] as! Bool {
                    FPCustomer.activeCustomer()!.balance += sum
                }
            }
            FPCardFlightManager.sharedInstance.cardFlightCard = nil
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            FPCardFlightManager.sharedInstance.cardFlightCard = nil
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kBalanceDeposit, parameters: params, success: success, failure: failure)
    }
    
    @discardableResult
    func customersForPage(_ page: Int, searchQuery: String, completion: @escaping (_ errMsg: String?, _ customers: [FPCustomer]?, _ nextPage: Int?) -> Void) -> URLSessionDataTask {
        let params = ["worker_id": FPFarmWorker.activeWorker()!.id, "search_query": searchQuery, "page": page, "items_per_page": 40] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var nextPage: Int?
            var errors: String? = kInternalError
            var customers = [FPCustomer]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["clients"] as! Array<NSDictionary> {
                        customers.append(FPModelParser.customerWithInfo(info))
                    }
                    nextPage = r["next_page"] as? Int
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, customers, nextPage)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            var timedOut = false
            if let e = error as NSError? {
                timedOut = e.code == NSURLErrorTimedOut
            }
            if (!self.reachabilityManager.isReachable || timedOut) {
                var customers = [FPCustomer]()
                if (searchQuery as NSString).length > 0 {
                    let cst = (FPDataAccessLayer.sharedInstance.allCustomers() as NSArray).filtered(using: NSPredicate(format: "name contains[cd] %@", searchQuery)) as! [FPCDCustomer]
                    customers = FPDataAccessLayer.sharedInstance.customersWithCDCustomers(cst)
                } else {
                    customers = FPDataAccessLayer.sharedInstance.customersWithCDCustomers(FPDataAccessLayer.sharedInstance.allCustomers())
                }
                completion(nil, customers, -1)
            } else {
                if let e = error as NSError? {
                    if e.code == -999 {
                        return
                    }
                }
                let errors = self.errors(error)
                completion(errors, nil, nil)
            }
        }
        
        return self.get(kCustomers, parameters: params, success: success, failure: failure)
    }
    
    func sendClientPurchaseHistoryForClient(_ client: FPCustomer, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["client_id": client.id]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String?
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        
        self.get(kClientSendPurchaseHistory, parameters: params, success: success, failure: failure)
    }
    
    //MARK: - Products
    func productsWithCompletion(_ completion: @escaping (_ errMsg: String?, _ products: Array<FPProduct>?) -> Void) {
        var params: Dictionary<String, AnyObject> = [:]
        if let worker = FPFarmWorker.activeWorker() {
            params["worker_id"] = worker.id as AnyObject?
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var prods: Array<FPProduct>?
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    var measurements: Array<FPMeasurement> = []
                    if let mRaw = r["measurements"] as? Array<Dictionary<String, AnyObject>> {
                        for mi in mRaw {
                            measurements.append(FPModelParser.measurementWithInfo(mi as NSDictionary))
                        }
                    }
                    FPMeasurement.setAllMeasurements(measurements)
                    
                    self.inventoryEnabled = r["inventory_enabled"] as! Bool
                    
                    var products: Array<FPProduct> = []
                    for pi in r["product_list"] as! Array<NSDictionary> {
                        products.append(FPModelParser.productWithInfo(pi))
                    }
                    FPProduct.setAllProducts(products)
                    prods = FPProduct.allProducts()!
                    FPProduct.synchronize()
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, prods)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            var timedOut = false
            if let e = error as NSError? {
                timedOut = e.code == NSURLErrorTimedOut
            }
            if (!self.reachabilityManager.isReachable || timedOut) {
                if let ap = FPProduct.allProducts() {
                    completion(nil, ap)
                }
            } else {
                let errors = self.errors(error)
                completion(errors, nil)
            }
        }
        
        self.get(kProducts, parameters: params, success: success, failure: failure)
    }
    
    func productCreateWithName(_ name: String, editProduct: FPProduct?, searchId: String, price: String, measurement: FPMeasurement, image: UIImage?, productCategory: FPProductCategory, availabilityDate: Date?, onSaleNow: Bool, hidden: Bool, trackInventory: Bool, supplier: FPProductSupplier?, triggerAmount: Double?, barcodeValue: String?, completion:@escaping (_ errMsg: String?, _ product: FPProduct?) -> Void) {
        
        var params = ["name": name, "price": price, "search_id": searchId, "measurement_id": "\(measurement.id)", "category_id": "\(productCategory.id)", "on_sale_now": onSaleNow ? "1" : "0", "hidden": hidden ? "1" : "0", "track_inventory": trackInventory ? "1" : "0"]
        
        if let s = supplier {
            params["supplier_id"] = "\(s.id)"
        }
        
        if let ta = triggerAmount {
            params["trigger_amount"] = "\(ta)"
        }
        
        if let bv = barcodeValue {
            params["barcode_value"] = bv
        }
        
        var path = kProductCreate
        if let ep = editProduct {
            path = kProductEdit
            params["product_id"] = "\(ep.id)"
        }
        
        let boundary = "---------------------------14737809831466499882746641449"
        let request = NSMutableURLRequest(url: URL(string: baseURL.absoluteString + path)!)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = NSMutableData()
        
        // file
        if let img = image {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(img.jpegData(compressionQuality: 0.7)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // params
        
        for (key, value) in params {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append(value.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--".data(using: .utf8)!)
        
        request.httpBody = body as Data
        
        // send request
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data: Data?, response: URLResponse?, error: Error?) in
            DispatchQueue.main.sync(execute: {
                if error != nil {
                    completion(self.errors(error), nil)
                } else if let data = data {
                    
                    var r: NSDictionary!
                    do {
                        r = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary
                    } catch {}
                    if r == nil {
                        completion("Error", nil)
                        return
                    }
                    var product: FPProduct?
                    if r["status"] as! Bool {
                        product = FPModelParser.productWithInfo(r["product"] as! NSDictionary)
                        var products = FPProduct.allProducts()!
                        if editProduct != nil {
                            let fp = products.filter({ return $0.id == product!.id })
                            if fp.count > 0 {
                                let p = fp[0]
                                p.mergeWithProduct(product!)
                            }
                        } else {
                            products.append(product!)
                            FPProduct.setAllProducts(products)
                        }
                        FPProduct.synchronize()
                    }
                    var errors: String? = kInternalError
                    errors = self.errors(r["errors"])
                    completion(errors, product)
                }
            })
        })
        
        task.resume()
    }
    
    func productCategoriesWithCompletion(_ completion: @escaping (_ errMsg: String?, _ categories: [FPProductCategory]?) -> Void) {
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var cats: [FPProductCategory]?
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    var categories = [FPProductCategory]()
                    for pi in r["product_categories"] as! [NSDictionary] {
                        categories.append(FPModelParser.productCategoryWithInfo(pi))
                    }
                    cats = categories
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, cats)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        
        self.get(kProductCategories, parameters: nil, success: success, failure: failure)
    }
    
    func ordersForDate(_ date: Date?, page: Int, completion: @escaping (_ errMsg: String?, _ orders: Array<FPOrder>?, _ nextPage: Int?) -> Void) -> URLSessionDataTask {
        var params: Dictionary<String, AnyObject> = ["page": page as AnyObject, "count": 40 as AnyObject, "worker_id": FPFarmWorker.activeWorker()!.id as AnyObject]
        
        if let d = date {
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy\'T\'HH:mm:ss"
            df.timeZone = TimeZone(abbreviation: "UTC")
            params["date"] = df.string(from: d) as AnyObject?
            params["time_offset"] = NSTimeZone.local.secondsFromGMT() as AnyObject?
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var nextPage: Int?
            var errors: String? = kInternalError
            var orders = [FPOrder]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["unfulfilled_orders"] as! Array<NSDictionary> {
                        orders.append(FPModelParser.orderWithInfo(info))
                    }
                    nextPage = r["page"] as? Int
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, orders, nextPage)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            if let error = error as NSError? {
                if error.code == -999 {
                    return
                }
            }
            let errors = self.errors(error)
            completion(errors, nil, nil)
        }
        return self.get(kOrders, parameters: params, success: success, failure: failure)
    }
    
    func orderCancel(_ order: FPOrder, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["purchase_id": order.id]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kOrderCancel, parameters: params, success: success, failure: failure)
    }
    
    func transactionsForDate(_ date: Date?, customer: FPCustomer?, page: Int, completion: @escaping (_ errMsg: String?, _ transactions: Array<FPTransaction>?, _ nextPage: Int?) -> Void) -> URLSessionDataTask {
        
        var returnAll: Bool = true
        if customer != nil {
            returnAll = true
        }
        
        var params: Dictionary<String, AnyObject> = ["page": page as AnyObject, "items_per_page": 40 as AnyObject, "worker_id": FPFarmWorker.activeWorker()!.id as AnyObject, "return_all": returnAll as AnyObject]
        
        if let d = date {
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy\'T\'HH:mm:ss"
            df.timeZone = TimeZone(abbreviation: "UTC")
            params["date"] = df.string(from: d) as AnyObject?
            params["time_offset"] = NSTimeZone.local.secondsFromGMT() as AnyObject?
        }
        
        if let c = customer {
            params["client_id"] = c.id as AnyObject?
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var nextPage: Int?
            var errors: String? = kInternalError
            var transactions = [FPTransaction]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["payments"] as! Array<NSDictionary> {
                        transactions.append(FPModelParser.transactionWithInfo(info))
                    }
                    nextPage = r["next_page"] as? Int
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, transactions, nextPage)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            if let error = error as NSError? {
                if error.code == -999 {
                    return
                }
            }
            let errors = self.errors(error)
            completion(errors, nil, nil)
        }
        return self.get(kTransactions, parameters: params, success: success, failure: failure)
    }
    
    func voidTransaction(_ t: FPTransaction, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["purchase_id": t.id, "worker_id": FPFarmWorker.activeWorker()!.id] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    let c = FPModelParser.customerWithInfo(r["client"] as! NSDictionary)
                    FPCustomer.setActiveCustomer(c)
                    c.voidTransactionProducts = r["product_list"] as? [NSDictionary]
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        
        self.post(kVoidTransaction, parameters: params, success: success, failure: failure)
    }
    
    func receiptForTransaction(_ transaction: FPTransaction, completion: @escaping (_ errMsg: String?, _ pdfURL: URL?) -> Void) {
        let params = ["id": transaction.id, "is_ordered": transaction.isOrdered] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            var pdfURL: URL?
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    pdfURL = URL(string: r["file_url"] as! String)
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, pdfURL)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        
        self.post(kTransactionReceipt, parameters: params, success: success, failure: failure)
    }
    
    func downloadFileWithURL(_ url: URL, completion: @escaping (_ errors: String?, _ path: String?) -> Void, progress: @escaping (_ progress: Float) -> Void) {
        let request = URLRequest(url: url)
        let operation = AFHTTPRequestOperation(request: request)
        
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent(url.lastPathComponent)
        
        operation?.outputStream = OutputStream(toFileAtPath: path, append: false)
        operation?.setDownloadProgressBlock { (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
            progress(Float(totalBytesRead) / Float(totalBytesExpectedToRead))
        }
        operation?.setCompletionBlockWithSuccess({ (operation, responseObject) -> Void in
            completion(nil, path)
            }, failure: { (operation, error) -> Void in
                completion(self.errors(error), nil)
        })
        operation?.start()
    }
    
    func paymentProcessWithSum(_ sum: Double?, method: FPPaymentMethod, checkNumber: String?, creditCard: FPCreditCard?, transactionToken : String?, last4: String?, completion:@escaping (_ errMsg: String?, _ didSaveOffline: Bool) -> Void) {
        
        var params = Dictionary<String, Any>()
        
        let dateFormatterUTC = DateFormatter()
        dateFormatterUTC.dateFormat = "dd-MM-yyyy'T'HH:mm:ss"
        dateFormatterUTC.timeZone = TimeZone(identifier: "UTC")
        params["date"] = dateFormatterUTC.string(from: Date()) as AnyObject?
        
        params["products"] = String(data: try! JSONSerialization.data(withJSONObject: FPCartView.sharedCart().paymentProducts(), options: .init(rawValue:0)), encoding: .utf8)
        
        var m = 0
        switch method {
        case .creditCard:
            m = 1
        case .cash:
            m = 2
        case .check:
            m = 3
        case .payLater:
            m = 4
        default:
            m = 0
        }
        
        params["payment_type"] = m as AnyObject?
        
        if let ac = FPCustomer.activeCustomer() {
            params["client_id"] = ac.id as AnyObject?
            
            if self.reachabilityManager.isReachable {
                var errMsg: String?
                if FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() {
                    let sCustomers = FPDataAccessLayer.sharedInstance.unsyncedCustomers().filter({ return $0.id.intValue == ac.id })
                    if sCustomers.count > 0 {
                        errMsg = "This customer has not yet been synchronized with online store. Please synchronize the database to use this customer's account online."
                    }
                }
                if FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() {
                    let sPurchases = FPDataAccessLayer.sharedInstance.unsyncedPurchases().filter({
                        return $0.clientId.intValue == ac.id
                    })
                    if sPurchases.count > 0 {
                        errMsg = "This customer has purchases that have not yet been synchronized with online store. Please synchronize the database to use this customer's account online."
                    }
                }
                if errMsg != nil {
                    completion(errMsg, false)
                    return
                }
            }
        }
        
        if let fw = FPFarmWorker.activeWorker() {
            params["worker_id"] = fw.id as AnyObject?
            if let rl = FPRetailLocation.defaultLocation() {
                params["location_id"] = rl.id as AnyObject?
            }
        }
        
        if let s = sum {
            params["sum"] = s as AnyObject?
        }
        
        params["sum_tax"] = FPCartView.sharedCart().totalTaxSum() as AnyObject?
        
        if let cn = checkNumber {
            if (cn as NSString).length > 0 {
                params["check_number"] = cn as AnyObject?
            }
        }
        
        if let c = creditCard {
            params["card_number"] = c.cardNumber! as AnyObject?
            params["cvv"] = c.cvv! as AnyObject?
            params["expiration_date"] = c.expirationDateString! as AnyObject?
        }
        
        if let ao = FPOrder.activeOrder() {
            params["purchase_id"] = ao.id as AnyObject?
        }
        
        if let tt = transactionToken {
            params["transaction_token"] = tt
        }
        
        if let l4 = last4 {
            params["last_4"] = l4 as AnyObject?
        }
        
        print("processing payment with params: \(params)")
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    if let ac = FPCustomer.activeCustomer() {
                        let customer = FPModelParser.customerWithInfo(r["client"] as! NSDictionary)
                        ac.balance = customer.balance
                        ac.farmBucks = customer.farmBucks
                        FPDataAccessLayer.sharedInstance.saveCustomer(ac)
                    }
                }
                FPCardFlightManager.sharedInstance.cardFlightCard = nil
                errors = self.errors(r["errors"])
            }
            
            completion(errors, false)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            FPCardFlightManager.sharedInstance.cardFlightCard = nil
            // Store failed purchase locally
            var timedOut = false
            if let e = error as NSError? {
                timedOut = e.code == NSURLErrorTimedOut
            }
            if (!self.reachabilityManager.isReachable || timedOut) {
                var clientId = -50_000 // burn
                if let ac = FPCustomer.activeCustomer() {
                    if method == FPPaymentMethod.payLater {
                        if ac.farmBucks > 0.00 {
                            var sum = FPCartView.sharedCart().sumWithTax
                            let fb = FPCartView.sharedCart().applicableFarmBucks // guaranteed to be non negative
                            let farmBucks = ac.farmBucks - fb
                            sum = max(sum - fb, 0.00)
                            let balance = ac.balance - sum
                            ac.farmBucks = farmBucks
                            ac.balance = balance
                        } else {
                            ac.balance -= FPCartView.sharedCart().sumWithTax
                        }
                    } else if method == FPPaymentMethod.cash {
                        ac.balance += sum! - FPCartView.sharedCart().checkoutSum
                        ac.farmBucks = ac.farmBucks - FPCartView.sharedCart().applicableFarmBucks
                    } else {
                        ac.farmBucks = ac.farmBucks - FPCartView.sharedCart().applicableFarmBucks
                    }
                    FPDataAccessLayer.sharedInstance.saveCustomer(ac)
                    clientId = ac.id
                }
                FPDataAccessLayer.sharedInstance.addPurchaseWithParams(params as NSDictionary, andClientId: clientId)
                completion(nil, true)
            } else {
                let errors = self.errors(error)
                completion(errors, false)
            }
        }
        
        self.requestSerializer.timeoutInterval = 20.0
        self.post(kPaymentProcess, parameters: params, success: success, failure: failure)
        self.requestSerializer.timeoutInterval = 60.0
    }
    
    func paymentCompareForProducts(_ products: [FPCartProduct], completion:(_ errMsg: String?, _ hasDiscrepancies: Bool) -> Void) {
        
    }
    
    func productSuppliersWithCompletion(_ completion: @escaping (_ errMsg: String?, _ suppliers: [FPProductSupplier]?) -> Void) -> URLSessionDataTask {
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var suppliers = [FPProductSupplier]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["suppliers"] as! [NSDictionary] {
                        suppliers.append(FPModelParser.productSupplierWithInfo(info)!)
                    }
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, suppliers)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        return self.get(kSuppliers, parameters: nil, success: success, failure: failure)
    }
    
    func giftCardsWithCompletion(_ completion:@escaping (_ errMsg: String?, _ giftCards: [FPGiftCard]?) -> Void) {
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var giftcards = [FPGiftCard]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for gi in r["gift_cards"] as! Array<NSDictionary> {
                        giftcards.append(FPModelParser.giftCardWithInfo(gi))
                    }
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, giftcards)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        self.get(kGiftCards, parameters: nil, success: success, failure: failure)
    }
    
    func giftCardPurchase(_ card: FPGiftCard, forEmail email: String, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["client_id": FPCustomer.activeCustomer()!.id, "gift_card_id": card.id, "email_recipient": email] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kGiftCardPurchase, parameters: params, success: success, failure: failure)
    }
    
    func giftCardRedeemWithCode(_ code: String, completion: @escaping (_ errMsg: String?, _ credits: Double?, _ cardSum: Double?) -> Void) {
        // Added shipping option flag
        let params = ["client_id": FPCustomer.activeCustomer()!.id, "gift_card_code": code, "shipping_option" : 2] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            var balance: Double?
            var sum: Double?
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    balance = r["balance"] as? Double
                    sum = r["gift_card_sum"] as? Double
                    FPCustomer.activeCustomer()!.balance = balance!
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, balance, sum)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil, nil)
        }
        self.post(kGiftCardRedeem, parameters: params, success: success, failure: failure)
    }
    
    func createCardflightToken(_ token: String, forClientId clientId: String, completion: @escaping (_ errMsg: String?) -> Void) {
        let params = ["client_id": clientId, "token": token]
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kCreateCardFlightToken, parameters: params, success: success, failure: failure)
    }
    
    func cardflightLogin(_ token: String, completion: @escaping (_ errMsg: String?, _ customer: FPCustomer?) -> Void) {
        let params = ["token": token]
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var customer: FPCustomer? = nil
            
            if let r = responseObject as? NSDictionary {
                
                if r["status"] as! Bool {
                    let customerInfo = r["client"] as! Dictionary<String, AnyObject>
                    customer = FPModelParser.customerWithInfo(customerInfo as NSDictionary)
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, customer)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        self.post(kCardflightLogin, parameters: params, success: success, failure: failure)
    }
    
    func productInventoryNoteCreateForProduct(_ product: FPProduct, text: String, completion:@escaping (_ errMsg: String?, _ note: FPInventoryProductNote?) -> Void) {
        let params = ["product_id": product.id, "text": text] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var note: FPInventoryProductNote? = nil
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    let noteInfo = r["note"] as! Dictionary<String, AnyObject>
                    note = FPModelParser.inventoryProductNoteWithInfo(noteInfo as NSDictionary)
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, note)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        self.post(kNotesAdd, parameters: params, success: success, failure: failure)
    }
    
    func productInventoryNoteDelete(_ note: FPInventoryProductNote, completion:@escaping (_ errMsg: String?) -> Void) {
        let params = ["note_id": note.id]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kNotesDelete, parameters: params, success: success, failure: failure)
    }
    
    func inventoryProductNotesForProduct(_ product: FPProduct, completion: @escaping (_ errMsg: String?, _ notes: [FPInventoryProductNote]?) -> Void) {
        let params = ["product_id": product.id]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var notes = [FPInventoryProductNote]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["notes"] as! [NSDictionary] {
                        notes.append(FPModelParser.inventoryProductNoteWithInfo(info))
                    }
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, notes)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        
        self.get(kProductNotes, parameters: params, success: success, failure: failure)
    }
    
    func productInventoryAddForProduct(_ product: FPProduct, amount: Double, type: Int, completion: @escaping (_ errMsg: String?, _ product: FPProduct?) -> Void) {
        
        let params = ["product_id": product.id, "amount": amount, "type": type] as [String : Any]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var product: FPProduct? = nil
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    product = FPModelParser.productWithInfo(r["product"] as! NSDictionary)
                    let products = FPProduct.allProducts()!
                    let fp = products.filter({ return $0.id == product!.id })
                    if fp.count > 0 {
                        let p = fp[0]
                        p.mergeWithProduct(product!)
                        FPProduct.synchronize()
                    }
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, product)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        
        self.post(kInventoryAdd, parameters: params, success: success, failure: failure)
    }
    
    func triggerAlertsForPage(_ page: Int, completion: @escaping (_ errMsg: String?, _ alerts: [FPTriggerAlert]?, _ nextPage: Int?) -> Void) {
        
        let params = ["page": page]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var nextPage: Int?
            var triggerAlerts = [FPTriggerAlert]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["trigger_alerts"] as! Array<NSDictionary> {
                        triggerAlerts.append(FPModelParser.triggerAlertWithInfo(info))
                    }
                    nextPage = r["next_page"] as? Int
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, triggerAlerts, nextPage)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil, nil)
        }
        
        self.get(kTriggerAlerts, parameters: params, success: success, failure: failure)
    }
    
    func inventoryProductHistoryItemsForPage(_ page: Int, product: FPProduct, completion: @escaping (_ errMsg: String?, _ historyItems: [FPInventoryProductHistory]?, _ nextPage: Int?) -> Void) {
        
        let params = ["page": page, "product_id": product.id]
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var nextPage: Int?
            var historyItems = [FPInventoryProductHistory]()
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    for info in r["inventory_history"] as! Array<NSDictionary> {
                        historyItems.append(FPModelParser.inventoryProductHistoryWithInfo(info))
                    }
                    nextPage = r["next_page"] as? Int
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, historyItems, nextPage)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil, nil)
        }
        
        self.get(kInventoryHistory, parameters: params, success: success, failure: failure)
    }
    
    func inventoryHistoryDelete(_ historyItem: FPInventoryProductHistory?, product: FPProduct, completion: @escaping (_ errMsg: String?, _ product: FPProduct?) -> Void) {
        
        var params = ["product_id": product.id]
        if let item = historyItem {
            params["product_inventory_id"] = item.id
        }
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            
            var errors: String? = kInternalError
            var product: FPProduct? = nil
            
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    product = FPModelParser.productWithInfo(r["product"] as! NSDictionary)
                    let products = FPProduct.allProducts()!
                    let fp = products.filter({ return $0.id == product!.id })
                    if fp.count > 0 {
                        let p = fp[0]
                        p.mergeWithProduct(product!)
                        FPProduct.synchronize()
                    }
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, product)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        
        self.post(kInventoryHistoryDelete, parameters: params, success: success, failure: failure)
    }
    
    //MARK: Obserers
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let st = self.syncDataTask {
            let received = Double(st.countOfBytesReceived)
            let expected = Double(st.countOfBytesExpectedToReceive)
            if expected > 0.0 {
                self.progress(received / expected)
            }
        }

    }
    
    // MARK: - Farm
    func cashCheckSummaryForCash(_ cash: Bool, withCompletion completion: @escaping (_ errors: String?, _ days: [NSDictionary]?) -> Void) {
        var params = [String: AnyObject]()
        params["is_cash"] = cash as AnyObject?
        if let location = FPRetailLocation.defaultLocation() {
            params["location_id"] =  location.id as AnyObject?
        }
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var days: [NSDictionary]?
            var errors: String?
            if let r = responseObject as? NSDictionary {
                if r["status"] as! Bool {
                    days = r["days"] as? [NSDictionary]
                }
                errors = self.errors(r["errors"])
            }
            
            completion(errors, days)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors, nil)
        }
        self.get(kCashCheckSummary, parameters: params, success: success, failure: failure)
    }
    
    func cashCheckSummarySetForCash(_ cash: Bool, withDays days: [NSDictionary], completion: @escaping (_ errors: String?) -> Void) {
        var params = [String: Any]()
        params["is_cash"] = cash as AnyObject?
        if let location = FPRetailLocation.defaultLocation() {
            params["location_id"] =  location.id as AnyObject?
        }
        if let farmWorker = FPFarmWorker.activeWorker() {
            params["farm_worker_id"] =  farmWorker.id as AnyObject?
        }
        let data = try! JSONSerialization.data(withJSONObject: days, options: .init(rawValue: 0))
        params["days"] = String(data: data, encoding: .utf8)
        
        let success = { (task: URLSessionDataTask?, responseObject: Any?) -> Void in
            var errors: String?
            if let r = responseObject as? NSDictionary {
                errors = self.errors(r["errors"])
            }
            completion(errors)
        }
        
        let failure = { (task: URLSessionDataTask?, error: Error?) -> Void in
            let errors = self.errors(error)
            completion(errors)
        }
        self.post(kCashCheckSummarySet, parameters: params, success: success, failure: failure)
    }
    
}
