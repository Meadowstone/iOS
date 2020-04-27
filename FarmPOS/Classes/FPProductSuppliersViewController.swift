//
//  FPProductSuppliersViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 22/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductSuppliersViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var supplierSelectedHandler: ((FPProductSupplier?) -> Void)!
    var suppliers = [FPProductSupplier]()
    var task: URLSessionDataTask?
    
    deinit {
        self.task?.cancel()
    }
    
    class func productSuppliersViewControllerWithSupplierSelectedHandler(_ handler: @escaping (FPProductSupplier?) -> Void) -> FPProductSuppliersViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FPProductSuppliersViewController") as! FPProductSuppliersViewController
        vc.supplierSelectedHandler = handler
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Select supplier"
        self.loadSuppliers()
    }
    
    func loadSuppliers() {
        self.suppliers = [FPProductSupplier(id: -1, companyName: "None", contactName: nil)]
        self.task?.cancel()
        self.task = FPServer.sharedInstance.productSuppliersWithCompletion({ (errMsg, suppliers) -> Void in
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else if let supp = suppliers {
                self.suppliers += supp
            }
            self.tableView.reloadData()
        })
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suppliers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        }
        let supplier = self.suppliers[indexPath.row]
        cell?.textLabel?.text = supplier.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var supplier: FPProductSupplier?
        if indexPath.row > 0 {
            supplier = suppliers[indexPath.row]
        }
        self.supplierSelectedHandler(supplier)
    }
    
}
