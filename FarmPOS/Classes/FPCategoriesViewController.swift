//
//  FPCategoriesViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPCategoriesViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource {

    var categories = [NSDictionary]()
    
    @IBOutlet weak var tableView: UITableView!
    
    
    class func categoriesViewController() -> FPCategoriesViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPCategoriesViewController") as! FPCategoriesViewController
        return vc
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPCategoriesViewController.refreshCategories), name: NSNotification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
        
        navigationItem.title = "Select category"
        
        tableView.register(UINib(nibName: "FPCategoryCell", bundle: nil), forCellReuseIdentifier: "FPCategoryCell")
        tableView.rowHeight = 76.0
        
        refreshCategories()
    }

    func refreshCategories() {
        categories = [NSDictionary]()

        if let products = FPProduct.allProducts() {
            let cSet = NSMutableSet()
            for product in products {
                cSet.add(product.category.name)
            }
            
            for category in cSet.allObjects as! [String] {
                var p: FPProduct?
                for product in products.reversed() {
                    if product.category.name == category {
                        if p == nil || p!.imageURL == nil {
                            p = product
                        }
                        if p!.imageURL != nil {
                            break
                        }
                    }
                }
                categories.append(["name": category, "product": p!])
            }
            
            categories.sort(by: { (d1, d2) -> Bool in
                let name1 = d1["name"] as! String
                let name2 = d2["name"] as! String
                return name1.lowercased() < name2.lowercased()
            })
            
            if let ac = FPCustomer.activeCustomer() {
                if ac.csas.count > 0 {
                    for product in products {
                        if product.csas.count > 0 {
                            // Removed CSA category
                            //categories.insert(["name": "CSA Products", "product": product], atIndex: 0)
                            break
                        }
                    }
                }
            }
        }

        tableView.reloadData()
    }
    
    //MARK: UITableView data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPCategoryCell") as! FPCategoryCell
        cell.categoryInfo = categories[indexPath.row]
        return cell
    }
    
    //MARK: UITableView delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let t = categories[indexPath.row]["name"] as? String {
            let vc = FPProductsViewController.productsViewControllerForCategory(t)
            navigationController!.pushViewController(vc, animated: true)
        }
    }
    
}
