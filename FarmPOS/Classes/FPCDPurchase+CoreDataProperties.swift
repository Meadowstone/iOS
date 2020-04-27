//
//  FPCDPurchase+CoreDataProperties.swift
//  
//
//  Created by Eugene Reshetov on 26/12/2016.
//
//

import Foundation
import CoreData


extension FPCDPurchase {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FPCDPurchase> {
        return NSFetchRequest<FPCDPurchase>(entityName: "FPCDPurchase");
    }
    
    @NSManaged public var params: Data
    @NSManaged public var clientId: NSNumber

}
