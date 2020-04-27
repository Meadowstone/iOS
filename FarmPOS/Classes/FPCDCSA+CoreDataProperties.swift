//
//  FPCDCSA+CoreDataProperties.swift
//  
//
//  Created by Eugene Reshetov on 26/12/2016.
//
//

import Foundation
import CoreData


extension FPCDCSA {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FPCDCSA> {
        return NSFetchRequest<FPCDCSA>(entityName: "FPCDCSA");
    }
    
    @NSManaged public var id: NSNumber
    @NSManaged public var name: String
    @NSManaged public var limit: NSNumber
    @NSManaged public var type: String
    @NSManaged public var customer: FPCDCustomer
    @NSManaged public var productDescriptor: FPCDProductDescriptor

}
