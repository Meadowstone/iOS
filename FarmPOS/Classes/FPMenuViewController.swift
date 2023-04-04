//
//  FPMenuViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/1/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD
import MMDrawerController

class FPMenuViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate {
    
    var items = ["Cart", "Customers", "Products", /*"Inventory"*/ "Transactions", "Orders", /*"Create New Product",*/ "Retail Location", "Synchronize", "Log Out"]
    var drawerController: MMDrawerController!

    @IBOutlet weak var tableView: UITableView!
    
    
    class func menuViewController() -> FPMenuViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPMenuViewController") as! FPMenuViewController
        return vc
    }
    
    class func instance() -> FPMenuViewController {
        return (FPAppDelegate.instance().window!.rootViewController as! MMDrawerController).leftDrawerViewController as! FPMenuViewController
    }
    
    class func setRootAndDisplay() {
        let centerVc = FPCartViewController.cartViewController()
        let centerNc = UINavigationController(rootViewController: centerVc)
        centerNc.navigationBar.isTranslucent = false
        
        let mVc = self.menuViewController()
        let item = MMDrawerBarButtonItem(target: mVc, action: #selector(FPMenuViewController.showMenu))
        centerVc.navigationItem.leftBarButtonItem = item
        
        let dc = MMDrawerController(center: centerNc, leftDrawerViewController: mVc)
        mVc.drawerController = dc
        FPAppDelegate.instance().window!.rootViewController = dc
        UIApplication.shared.statusBarStyle = .lightContent
        
        FPServer.sharedInstance.checkUpdates { (hasUpdates) -> Void in
            if hasUpdates {
                FPSyncManager.sharedInstance.syncWithCompletion { [weak mVc] in
                    mVc!.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hiv = UIImageView(image: UIImage(named: "farmstand_logo"))
        hiv.contentMode = .scaleAspectFit
        hiv.frame = CGRect(x: 0.0, y: 0.0, width: 253, height: 130)
        tableView.tableHeaderView = hiv
        
        tableView.contentInset = UIEdgeInsets(top: 15.0, left: 0.0, bottom: 0.0, right: 0.0)
        tableView.contentOffset = CGPoint(x: 0.0, y: -tableView.contentInset.top)
        tableView.tableFooterView = UIView() // to remove unused separators

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.statusBarStyle = .default
    }
    
    func redirectToCart() {
        let vc = FPCartViewController.cartViewController()
        let centerNc = UINavigationController(rootViewController: vc)
        let item = MMDrawerBarButtonItem(target: self, action: #selector(FPMenuViewController.showMenu))
        vc.navigationItem.leftBarButtonItem = item
        centerNc.navigationBar.isTranslucent = false
        drawerController.centerViewController = centerNc
    }
    
    //MARK: MMDrawerController related
    @objc func showMenu() {
        tableView.reloadData()
        view.endEditing(true)
        if drawerController.openSide == .left {
            UIApplication.shared.statusBarStyle = .lightContent
            drawerController.closeDrawer(animated: true, completion: nil)
        } else {
            UIApplication.shared.statusBarStyle = .default
            drawerController.open(.left, animated: true, completion: nil)
            // Tread lightly
            if let nc = drawerController.centerViewController as? UINavigationController {
                if let vc = nc.topViewController as? FPCustomersViewController {
                    vc.searchBar.resignFirstResponder()
                }
                if let vc = nc.topViewController as? FPProductsViewController {
                    vc.searchBar.resignFirstResponder()
                }
            }
        }
    }
    
    //MARK: UITableView data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellId = "menuCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
            cell!.detailTextLabel!.textColor = UIColor.lightGray
        }
        let text = items[indexPath.row]
        cell!.textLabel!.text = text
        if text == "Synchronize" {
            var message = ""
            if FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() {
                message = "Unsynced: \(FPDataAccessLayer.sharedInstance.unsyncedPurchases().count) payments"
            }
            if FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() {
                message = message + "  \(FPDataAccessLayer.sharedInstance.unsyncedCustomers().count) customers"
            }
            if (message as NSString).length == 0 {
                message = "Last synced: "
                if let s = UserDefaults.standard.object(forKey: FPDatabaseSyncDateUserDefaultsKey) as? Date {
                    let df = DateFormatter()
                    df.dateFormat = "MM/dd/yyyy hh:mm a"
                    message = message + df.string(from: s)
                } else {
                    message = message + "Never"
                }
            }
            cell!.detailTextLabel!.text = message
        } else if text == "Customers" {
            if let ac = FPCustomer.activeCustomer() {
                cell!.detailTextLabel!.text = "Assigned: " + ac.name
            } else {
                cell!.detailTextLabel!.text = ""
            }
        } else if text == "Orders" {
            if let order = FPOrder.activeOrder() {
                cell!.detailTextLabel!.text = "Processing for: " + order.customer.name
            } else {
                cell!.detailTextLabel!.text = ""
            }
        } else if text == "Retail Location" {
            if let loc = FPRetailLocation.defaultLocation() {
                cell!.detailTextLabel!.text = loc.name
            } else {
                cell!.detailTextLabel!.text = "None"
            }
        }
        else if text == "Cart" {
            let cp = FPCartView.sharedCart().cartProducts
            if cp.count > 0 {
                cell!.detailTextLabel!.text = "Sum: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().sumWithTax)
            } else {
                cell!.detailTextLabel!.text = ""
            }
        } else {
            cell!.detailTextLabel!.text = ""
        }
        return cell!
    }
    
    //MARK: UITableView delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let text = items[indexPath.row]
        var vc: UIViewController?
        if text == "Synchronize" {
            if FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() || FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() {
                let alert = UIAlertView()
                alert.tag = 2
                alert.delegate = self
                alert.addButton(withTitle: "Resolve sync issues")
                alert.addButton(withTitle: "Sync database")
                alert.addButton(withTitle: "Cancel")
                alert.show()
            } else {
                FPSyncManager.sharedInstance.syncWithCompletion { [weak self] in
                    self!.tableView.reloadData()
                }
            }
        } else if text == "Log Out" {
            let alert = UIAlertView()
            alert.tag = 1
            alert.delegate = self
            alert.title = "Log Out?"
            alert.addButton(withTitle: "Log Out")
            alert.addButton(withTitle: "Cancel")
            alert.show()
//        } else if text == "Products" {
//            vc = FPCategoriesViewController.categoriesViewController()
        } else if text == "Products" {
            vc = FPProductsViewController.productsViewControllerForCategory(nil, inventory: true)
        } else if text == "Cart" {
            vc = FPCartViewController.cartViewController()
        } else if text == "Customers" {
            vc = FPCustomersViewController.customersViewController()
        } else if text == "Transactions" {
            vc = FPTransactionsViewController.transactionsViewControllerForCustomer(nil)
        } else if text == "Orders" {
            let handler = {
                [weak self] (order: FPOrder) -> Void in
                // Clear the cart
                FPCartView.sharedCart().resetCart()
                
                // Step 1: re-authenticate the customer
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Processing"
                FPServer.sharedInstance.customerAuthenticateWithPhone(order.customer.phone, pin: order.customer.pin, completion: { (errMsg: String?, customer: FPCustomer?) -> Void in
                    hud?.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    } else {
                        order.customer = customer!
                        FPCustomer.setActiveCustomer(order.customer)
                        
                        // Step 2: process the products
                        FPOrder.setActiveOrder(order)
                        
                        self!.redirectToCart()
                    }
                })
            }
            vc = FPOrdersViewController.ordersViewControllerWithOrderSelectedHandler(handler)
        } else if text == "Retail Location" {
            if let rls = FPRetailLocation.allRetailLocationsNames() {
                if rls.count > 0 {
                    var name = "None"
                    if let location = FPRetailLocation.defaultLocation() {
                        name = location.name
                    }
                    let alert = UIAlertView(title: "Retail location", message: "Current location: \(name)", delegate: self, cancelButtonTitle: "Cancel")
                    alert.addButton(withTitle: "Change")
                    alert.alertViewStyle = .plainTextInput
                    let textField = alert.textField(at: 0)!
                    textField.placeholder = "No location"
                    var dataSource = ["None"]
                    dataSource += rls
                    textField.inputView = FPChoiceInputView.choiceInputViewWithDataSource(dataSource,
                        completion: { [weak self] (choice: String) -> Void in
                            let textField = alert.textField(at: 0)!
                            textField.text = choice
                            if textField.text != "None" {
                                FPRetailLocation.makeDefault(textField.text!)
                            } else {
                                FPRetailLocation.removeDefault()
                            }
                            alert.dismiss(withClickedButtonIndex: 1, animated: true)
                            self!.tableView.reloadData()
                        })
                    alert.show()
                }
            }
        } else if text == "Create New Product" {
            vc = FPProductCreateViewController.productCreateViewControllerWithCompletion({
                [weak self] product in
                if let p = product {
                    FPAlertManager.showMessage("\(p.name) - successfully created!", withTitle: "Success!")
                }
                self!.redirectToCart()
                self!.dismiss(animated: true, completion: nil)
                }, product: nil)
            let nc = UINavigationController(rootViewController: vc!)
            present(nc, animated: true, completion: nil)
            return
        }
        
        if let v = vc {
            let centerNc = UINavigationController(rootViewController: v)
            centerNc.navigationBar.isTranslucent = false
            drawerController.centerViewController = centerNc
            
            let item = MMDrawerBarButtonItem(target: self, action: #selector(FPMenuViewController.showMenu))
            v.navigationItem.leftBarButtonItem = item
            
            showMenu()
        }
    }
    
    //MARK: UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 1 && buttonIndex == 0 {
            NotificationCenter.default.post(name: Notification.Name(rawValue: FPUserLoginStatusChanged), object: ["status": FPLoginStatus.loggedOut.rawValue, "user": FPUser()])
        } else if alertView.tag == 2 {
            if buttonIndex == 0 {
                let vc = FPUnsyncedItemsTableViewController.unsyncedItemsTableViewController()
                let centerNc = UINavigationController(rootViewController: vc)
                centerNc.navigationBar.isTranslucent = false
                drawerController.centerViewController = centerNc
                let item = MMDrawerBarButtonItem(target: self, action: #selector(FPMenuViewController.showMenu))
                vc.navigationItem.leftBarButtonItem = item
                
                showMenu()
            } else if buttonIndex == 1 {
                FPCartView.sharedCart().resetCart()
                FPSyncManager.sharedInstance.syncWithCompletion { [weak self] in
                    self!.tableView.reloadData()
                }
            }
        }
    }
}
