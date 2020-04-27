//
//  FPCDCustomer+CoreDataProperties.swift
//  
//
//  Created by Eugene Reshetov on 26/12/2016.
//
//

import Foundation
import CoreData


extension FPCDCustomer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FPCDCustomer> {
        return NSFetchRequest<FPCDCustomer>(entityName: "FPCDCustomer");
    }
        
    @NSManaged public var address: String?
    @NSManaged public var balance: NSNumber
    @NSManaged public var farmBucks: NSNumber
    @NSManaged public var city: String?
    @NSManaged public var email: String
    @NSManaged public var hasCreditCard: NSNumber
    @NSManaged public var wholesale: NSNumber
    @NSManaged public var hasOverdueBalance: NSNumber
    @NSManaged public var id: NSNumber
    @NSManaged public var name: String
    @NSManaged public var phone: String
    @NSManaged public var phoneHome: String?
    @NSManaged public var pin: String
    @NSManaged public var state: String?
    @NSManaged public var synchronized: NSNumber
    @NSManaged public var zip: String?
    @NSManaged public var csas: NSSet
    @NSManaged public var productDescriptors: NSSet

}

// MARK: Generated accessors for csas
extension FPCDCustomer {

    @objc(addCsasObject:)
    @NSManaged public func addToCsas(_ value: FPCDCSA)

    @objc(removeCsasObject:)
    @NSManaged public func removeFromCsas(_ value: FPCDCSA)

    @objc(addCsas:)
    @NSManaged public func addToCsas(_ values: NSSet)

    @objc(removeCsas:)
    @NSManaged public func removeFromCsas(_ values: NSSet)

}

// MARK: Generated accessors for productDescriptors
extension FPCDCustomer {

    @objc(addProductDescriptorsObject:)
    @NSManaged public func addToProductDescriptors(_ value: FPCDProductDescriptor)

    @objc(removeProductDescriptorsObject:)
    @NSManaged public func removeFromProductDescriptors(_ value: FPCDProductDescriptor)

    @objc(addProductDescriptors:)
    @NSManaged public func addToProductDescriptors(_ values: NSSet)

    @objc(removeProductDescriptors:)
    @NSManaged public func removeFromProductDescriptors(_ values: NSSet)

}
