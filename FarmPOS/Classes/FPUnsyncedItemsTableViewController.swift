//
//  FPUnsyncedItemsTableViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 26/08/2014.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPUnsyncedItemsTableViewController: FPRotationTableViewController, UIAlertViewDelegate {
    
    var items: [AnyObject]!
    var showsCustomers = true
    var processingPurchase: FPCDPurchase?
    
    class func unsyncedItemsTableViewController() -> FPUnsyncedItemsTableViewController {
        return FPUnsyncedItemsTableViewController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: 640, height: 468)
        
        let fs = UISegmentedControl(items: ["Customers", "Payments"])
        fs.selectedSegmentIndex = 0
        fs.frame = CGRect(x: 0.0, y: 0.0, width: 200.0, height: fs.frame.size.height)
        fs.addTarget(self, action: #selector(FPUnsyncedItemsTableViewController.filterChanged(_:)), for: .valueChanged)
        fs.sendActions(for: .valueChanged)
        navigationItem.titleView = fs
        
        tableView.register(UINib(nibName: "FPCustomerCell", bundle: nil), forCellReuseIdentifier: "FPCustomerCell")
        tableView.register(UINib(nibName: "FPUnsyncedPurchaseCell", bundle: nil), forCellReuseIdentifier: "FPUnsyncedPurchaseCell")
    }
    
    @objc func filterChanged(_ sc: UISegmentedControl) {
        showsCustomers = sc.selectedSegmentIndex == 0
        updateContents()
    }
    
    func updateContents() {
        if showsCustomers {
            var cs = [FPCustomer]()
            for c in FPDataAccessLayer.sharedInstance.unsyncedCustomers() {
                cs.append(FPDataAccessLayer.sharedInstance.customerWithCDCustomer(c))
            }
            items = cs
        } else {
            items = FPDataAccessLayer.sharedInstance.unsyncedPurchases()
        }
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height: CGFloat = 0.00
        if showsCustomers {
            height = FPCustomerCell.cellHeightForCustomer(items[indexPath.row] as! FPCustomer)
        } else {
            height = FPUnsyncedPurchaseCell.cellHeightForPurchase(items[indexPath.row] as! FPCDPurchase, tableView: tableView)
        }
        return height
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if showsCustomers {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FPCustomerCell", for: indexPath) as! FPCustomerCell
            cell.displayId = true
            cell.balanceBtn.isHidden = true
            cell.transactionsBtn.isHidden = true
            cell.customer = items[indexPath.row] as! FPCustomer
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FPUnsyncedPurchaseCell", for: indexPath) as! FPUnsyncedPurchaseCell
            cell.tableView = tableView // burn
            cell.purchase = items[indexPath.row] as! FPCDPurchase
            return cell
        }
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if showsCustomers {
                let customer = items[indexPath.row] as! FPCustomer
                let c = FPDataAccessLayer.sharedInstance.customerWithPhone(customer.phone, andPin: customer.pin)
                items.remove(at: indexPath.row)
                FPDataAccessLayer.sharedInstance.managedObjectContext.delete(c!)
            } else {
                FPDataAccessLayer.sharedInstance.managedObjectContext.delete(items[indexPath.row] as! FPCDPurchase)
                items.remove(at: indexPath.row)
            }
            FPDataAccessLayer.sharedInstance.save()
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if !showsCustomers {
            processingPurchase = items[indexPath.row] as? FPCDPurchase
            let alert = UIAlertView()
            alert.delegate = self
            alert.title = "Warning!"
            alert.message = "Changing client_id will result in this purchase being moved to another customer. Proceed with caution!"
            alert.alertViewStyle = .plainTextInput
            alert.textField(at: 0)!.keyboardType = UIKeyboardType.numbersAndPunctuation
            alert.tag = 1
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.show()
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 {
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "en_US")
            if let n = nf.number(from: alertView.textField(at: 0)!.text!) {
                processingPurchase!.clientId = n
                var params = NSKeyedUnarchiver.unarchiveObject(with: processingPurchase!.params as Data) as! [String: AnyObject]
                params["client_id"] = n
                processingPurchase!.params = NSKeyedArchiver.archivedData(withRootObject: params)
                FPDataAccessLayer.sharedInstance.save()
                updateContents()
            } else {
                FPAlertManager.showMessage("Please enter valid number", withTitle: "Operation aborted")
            }
            processingPurchase = nil
        }
    }
    
}
