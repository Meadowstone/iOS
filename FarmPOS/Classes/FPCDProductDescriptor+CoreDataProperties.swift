//
//  FPCDProductDescriptor+CoreDataProperties.swift
//  
//
//  Created by Eugene Reshetov on 26/12/2016.
//
//

import Foundation
import CoreData


extension FPCDProductDescriptor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FPCDProductDescriptor> {
        return NSFetchRequest<FPCDProductDescriptor>(entityName: "FPCDProductDescriptor");
    }
    
    @NSManaged public var productId: NSNumber
    @NSManaged public var discountPrice: NSNumber?
    @NSManaged public var csas: NSSet
    @NSManaged public var customer: NSManagedObject

}

// MARK: Generated accessors for csas
extension FPCDProductDescriptor {

    @objc(addCsasObject:)
    @NSManaged public func addToCsas(_ value: FPCDCSA)

    @objc(removeCsasObject:)
    @NSManaged public func removeFromCsas(_ value: FPCDCSA)

    @objc(addCsas:)
    @NSManaged public func addToCsas(_ values: NSSet)

    @objc(removeCsas:)
    @NSManaged public func removeFromCsas(_ values: NSSet)

}
