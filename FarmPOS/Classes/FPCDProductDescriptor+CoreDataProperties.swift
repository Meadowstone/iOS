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
    @NSManaged public var customer: NSManagedObject

}
