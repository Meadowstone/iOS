//
//  FPDataAccessLayer.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 7/31/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import CoreData

class FPDataAccessLayer : NSObject {
    
    private let documentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask)[0]
    
    public lazy var objectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: "DataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    public lazy var storeCoordinator: NSPersistentStoreCoordinator = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.objectModel)
        let url = self.documentsURL.appendingPathComponent("db.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
        } catch {
            // Report any error we got.
            var dict = [String: Any]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        return coordinator
    }()
    
    public lazy var managedObjectContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.storeCoordinator
        return managedObjectContext
    }()
    
    static let sharedInstance = FPDataAccessLayer()
    
    //MARK: Save
    func save() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    //MARK: Customers
    func persistCustomers(_ customers: [NSDictionary]) {
        self.deleteAllSyncedCustomers()
        for info in customers {
            _ = self.createCustomerWithInfo(info)
        }
        self.save()
    }
    
    func deleteAllSyncedCustomers() {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDCustomer")
        fr.predicate = NSPredicate(format: "synchronized == TRUE")
        for c in try! managedObjectContext.fetch(fr) as! [FPCDCustomer] {
            managedObjectContext.delete(c)
        }
        self.save()
    }
    
    @discardableResult
    func createCustomerWithInfo(_ info: NSDictionary) -> FPCDCustomer {
        let c = NSEntityDescription.insertNewObject(forEntityName: "FPCDCustomer", into: self.managedObjectContext) as! FPCDCustomer
        c.id = NSNumber(value: info["client_id"] as! Int)
        c.wholesale = info["wholesale"] as! Bool as NSNumber
        c.name = info["name"] as! String
        c.balance = NSNumber(value: info["balance"] as! Double)
        c.farmBucks = NSNumber(value: ((info["farm_bucks"] as? Double) != nil ? info["farm_bucks"] as! Double : 0.00))
        c.hasCreditCard = info["has_credit_card"] as! Bool as NSNumber
        c.hasOverdueBalance = info["has_overdue_balance"] as! Bool as NSNumber
        c.email = info["email"] as! String
        c.pin = info["pin"] as! String
        c.phone = info["phone"] as! String
        c.phone = (c.phone.components(separatedBy: CharacterSet(charactersIn: " -()")) as NSArray).componentsJoined(by: "")
        if let phoneHome = info["phone_home"] as? String {
            c.phoneHome = phoneHome
        }
        if let city = info["city"] as? String {
            c.city = city
        }
        if let state = info["state"] as? String {
            c.state = state
        }
        if let zip = info["zip_code"] as? String {
            c.zip = zip
        }
        if let address = info["address"] as? String {
            c.address = address
        }
        if let synchronized = info["synchronized"] as? Bool {
            c.synchronized = synchronized as NSNumber
        }
        
//        CLSLogv("%@", getVaList(["started saving product descriptors "]))
        
        let productDescriptorWithInfo = { (info: NSDictionary) -> FPCDProductDescriptor in
            let pd = NSEntityDescription.insertNewObject(forEntityName: "FPCDProductDescriptor", into: self.managedObjectContext) as! FPCDProductDescriptor
            pd.productId = NSNumber(value: info["product_id"] as! Int)
            if let discountPrice = info["discount_price"] as? Double {
                pd.discountPrice = discountPrice as NSNumber?
            }
            return pd
        }
//        CLSLogv("%@", getVaList(["started saving products"]))
        var pds = [FPCDProductDescriptor]()
        if let ps = info["products"] as? [NSDictionary] {
            for info in ps {
                let pd = productDescriptorWithInfo(info)
                pd.customer = c
                pds.append(pd)
            }
        }
        
//        if pds.count > 0 {
//            print("coordinator \(storeCoordinator)")
//            print("context \(managedObjectContext)")
//            print("!OBJECT! \(c)")
//            print("!Descriptors! \(c.productDescriptors)")
//            c.productDescriptors = NSSet().adding(pds) as NSSet
//        }
        
        return c
    }
    
    func hasUnsyncedCustomers() -> Bool {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDCustomer")
        fr.predicate = NSPredicate(format: "synchronized == FALSE")
        let count = try! managedObjectContext.count(for: fr)
        return count > 0
    }
    
    func unsyncedCustomers() -> [FPCDCustomer] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDCustomer")
        fr.predicate = NSPredicate(format: "synchronized == FALSE")
        return try! managedObjectContext.fetch(fr) as! [FPCDCustomer]
    }
    
    func allCustomers() -> [FPCDCustomer] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDCustomer")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        return try! managedObjectContext.fetch(fr) as! [FPCDCustomer]
    }
    
    func saveCustomer(_ customer: FPCustomer, searchByID: Bool = false) {
//        CLSLogv("%@", getVaList(["getting customer with phone"]))
        var c: FPCDCustomer?
        if searchByID {
            c = self.customerWithID(customer.id)
        } else {
            c = self.customerWithPhone(customer.phone, andPin: customer.pin)
        }
//        CLSLogv("%@", getVaList(["removing customer"]))
        managedObjectContext.delete(c!)
//        CLSLogv("%@", getVaList(["creating customer with info"]))
        _ = self.createCustomerWithInfo(FPModelParser.infoWithCustomer(customer))
//        CLSLogv("%@", getVaList(["saving"]))
        self.save()
//        CLSLogv("%@", getVaList(["customer save finished"]))
    }
    
    func customerWithID(_ id: Int) -> FPCDCustomer? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDCustomer")
        fr.predicate = NSPredicate(format: "id == %@", NSNumber(value: id as Int))
        let customers = try! managedObjectContext.fetch(fr) as! [FPCDCustomer]
        if customers.count > 0 {
            return customers[0]
        } else {
            return nil
        }
    }
    
    func customerWithPhone(_ phone: String, andPin pin: String) -> FPCDCustomer? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDCustomer")
        fr.predicate = NSPredicate(format: "phone == %@ && pin == %@", phone, pin)
        let customers = try! managedObjectContext.fetch(fr) as! [FPCDCustomer]
        if customers.count > 0 {
            return customers[0]
        } else {
            return nil
        }
    }
    
    func updateCustomersAndPurchasesWithCustomers(_ customers: [NSDictionary]) {
        let storedCustomers = self.unsyncedCustomers()
        let storedPurchases = self.unsyncedPurchases()
        for info in customers {
            let cachedCustomer = storedCustomers.filter({ return $0.email == info["email"] as! String })[0]
            let id = cachedCustomer.id
            cachedCustomer.id = NSNumber(value: info["client_id"] as! Int)
            cachedCustomer.synchronized = true
            let purchases = storedPurchases.filter({
                return $0.clientId == id
            })
            if purchases.count > 0 {
                for p in purchases {
                    p.clientId = cachedCustomer.id
                    let params = (NSKeyedUnarchiver.unarchiveObject(with: p.params as Data) as! NSDictionary).mutableCopy() as! NSMutableDictionary
                    params["client_id"] = cachedCustomer.id
                    p.params = NSKeyedArchiver.archivedData(withRootObject: params)
                }
            }
        }
        self.save()
    }
    
    // Used to synchronize unsynced customers only
    func infoWithCustomer(_ c: FPCDCustomer) -> NSDictionary {
        var info = [String: Any]()
        info["name"] = c.name
        info["email"] = c.email
        info["pin"] = c.pin
        info["phone"] = c.phone
        
        if let ph = c.phoneHome {
            info["phone_home"] = ph
        }
        
        if let city = c.city {
            info["city"] = city
        }
        
        if let state = c.state {
            info["state"] = state
        }
        
        if let zip = c.zip {
            info["zip_code"] = zip
        }
        
        if let address = c.address {
            info["address"] = address
        }
        
        return info as NSDictionary
    }
    
    // Mutations
    func customerWithCDCustomer(_ cd: FPCDCustomer) -> FPCustomer {
        let c = FPCustomer()
        c.id = cd.id.intValue
        c.balance = cd.balance.doubleValue
        c.farmBucks = cd.farmBucks.doubleValue
        c.name = cd.name
        c.email = cd.email
        c.pin = cd.pin
        c.phone = cd.phone
        c.hasCreditCard = cd.hasCreditCard.boolValue
        c.hasOverdueBalance = cd.hasOverdueBalance.boolValue
        c.phoneHome = cd.phoneHome
        c.city = cd.city
        c.state = cd.state
        c.zip = cd.zip
        c.address = cd.address
        c.synchronized = cd.synchronized.boolValue
        
        var pds = [FPProductDescriptor]()
        if let ps = cd.productDescriptors.allObjects as? [FPCDProductDescriptor] {
            for pd in ps {
                var info = [String: Any]()
                info["product_id"] = pd.productId
                if let dp = pd.discountPrice {
                    info["discount_price"] = dp
                }
                pds.append(FPModelParser.productDescriptorWithInfo(info as NSDictionary))
            }
        }
        c.productDescriptors = pds
        
        return c
    }
    
    func customersWithCDCustomers(_ customers: [FPCDCustomer]) -> [FPCustomer] {
        var cst = [FPCustomer]()
        for c in customers {
            cst.append(self.customerWithCDCustomer(c))
        }
        return cst
    }
    
    func usableCustomerId() -> Int {
        var id: Int = -1
        if self.hasUnsyncedCustomers() {
            let customers = self.unsyncedCustomers().sorted(by: { c1, c2 in return c1.id.intValue < c2.id.intValue })
            id = customers[0].id.intValue - 1
        }
        return id
    }
    
    func hasUnsyncedPurchases() -> Bool {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDPurchase")
        let count = try! managedObjectContext.count(for: fr)
        return count > 0
    }
    
    func unsyncedPurchases() -> [FPCDPurchase] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDPurchase")
        return try! managedObjectContext.fetch(fr) as! [FPCDPurchase]
    }
    
    func deleteAllPurchases() {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDPurchase")
        for c in try! managedObjectContext.fetch(fr) as! [FPCDPurchase] {
            managedObjectContext.delete(c)
        }
        self.save()
    }
    
    func allPurchasesInfo() -> [NSDictionary] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDPurchase")
        var dicts = [NSDictionary]()
        for p in try! managedObjectContext.fetch(fr) as! [FPCDPurchase] {
            dicts.append(NSKeyedUnarchiver.unarchiveObject(with: p.params) as! NSDictionary)
        }
        return dicts
    }
    
    func addPurchaseWithParams(_ params: NSDictionary, andClientId clientId: Int) {
        let p = NSEntityDescription.insertNewObject(forEntityName: "FPCDPurchase", into: managedObjectContext) as! FPCDPurchase
        p.params = NSKeyedArchiver.archivedData(withRootObject: params)
        p.clientId = NSNumber(value: clientId)
        self.save()
    }
    
    func customerHasUnsyncedPurchases(_ customer: FPCDCustomer) -> Bool {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "FPCDPurchase")
        fr.predicate = NSPredicate(format: "clientId == %@", customer.id)
        let count = try! managedObjectContext.count(for: fr)
        return count > 0
    }
    
}
