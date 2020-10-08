//
//  FPProductsAndCartViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/1/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit
import MBProgressHUD

class FPProductsAndCartViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate, UIAlertViewDelegate, UISearchBarDelegate, UITextFieldDelegate, FPProductCartCellDelegate, FPCartViewDelegate, FPProductViewControllerDelegate, FPProductCategoriesFooterViewDelegate {
    
    var showingCategories = false
    var popover: UIPopoverController?
    var cartView: FPCartView!
    var categoriesFooterView: FPProductCategoriesFooterView!
    var refreshBtn: UIButton!
    var markImageView: UIImageView!
    var headerTitleLabel: UILabel!
    var searchBar: UISearchBar!
    var categoriesBtn: UIButton!
    var sections = [Dictionary<String, AnyObject>]()
    var sectionsBackup = [Dictionary<String, AnyObject>]()
    var products = [FPProduct]()
    var alert : UIAlertView!
    
    var categorySelected = false
    
    var largeSearchView = true
    
    var searchTextField: UITextField!
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var cartPlaceholderView: UIView!
    @IBOutlet weak var categoriesFooterPlaceholderView: UIView!
    
    class func productsAndCartViewController() -> FPProductsAndCartViewController {
        return FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPProductsAndCartViewController") as! FPProductsAndCartViewController
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsAndCartViewController.updateUI), name: NSNotification.Name(rawValue: FPDatabaseSyncStatusChangedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsAndCartViewController.processOrderOrTransaction), name: NSNotification.Name(rawValue: FPTransactionOrOrderProcessingNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsAndCartViewController.customerAuthenticated), name: NSNotification.Name(rawValue: FPCustomerAuthenticatedNotification), object: nil)
        
        // Navigation bar left view - Log Out / Help
        let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 64.0))
        leftView.isUserInteractionEnabled = true;
        leftView.backgroundColor = UIColor.clear;
        
        let logoutBtn = UIButton(type: .custom)
        logoutBtn.addTarget(self, action: #selector(FPProductsAndCartViewController.logoutPressed), for: .touchUpInside)
        logoutBtn.setTitle("Log Out", for: .normal)
        logoutBtn.setTitleColor(UIColor.lightGray, for: .highlighted)
        logoutBtn.sizeToFit()
        logoutBtn.frame.size.height = leftView.frame.size.height
        leftView.addSubview(logoutBtn)
        leftView.frame = CGRect(x: 0.0, y: 0.0, width: logoutBtn.frame.size.width + logoutBtn.frame.origin.x, height: 64.0);
        
//        let locationBtn = UIButton.buttonWithType(.Custom) as! UIButton
//        locationBtn.addTarget(self, action: "locationPressed", forControlEvents: .TouchUpInside)
//        locationBtn.setTitleColor(UIColor.lightGrayColor(), forState: .Highlighted)
//        locationBtn.setTitle("Retail location", forState: .Normal)
//        locationBtn.titleEdgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 0.0)
//        locationBtn.sizeToFit()
//        locationBtn.frame = CGRectMake(logoutBtn.frame.size.width + logoutBtn.frame.origin.x + 8.0, 0.0, locationBtn.frame.size.width + 8.0, 64.0);
        
        let summaryBtn = UIButton(type: .custom)
        summaryBtn.addTarget(self, action: #selector(FPProductsAndCartViewController.summaryPressed), for: .touchUpInside)
        summaryBtn.setTitleColor(UIColor.lightGray, for: .highlighted)
        summaryBtn.setTitle("Cash / Check Summary", for: .normal)
        summaryBtn.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 8.0, bottom: 0.0, right: 0.0)
        summaryBtn.sizeToFit()
        summaryBtn.frame = CGRect(x: logoutBtn.frame.size.width + logoutBtn.frame.origin.x + 8.0, y: 0.0, width: summaryBtn.frame.size.width + 8.0, height: 64.0);
        
        if FPFarmWorker.activeWorker() != nil {
            leftView.addSubview(summaryBtn)
            leftView.frame = CGRect(x: 0.0, y: 0.0, width: summaryBtn.frame.size.width + summaryBtn.frame.origin.x, height: 64.0)
//            locationBtn.hidden = false
//            if let rls = FPRetailLocation.allRetailLocations() {
//                if rls.count > 0 {
//                    leftView.addSubview(locationBtn)
//                    leftView.frame = CGRectMake(0.0, 0.0, locationBtn.frame.size.width + locationBtn.frame.origin.x, 64.0);
//                }
//            }
        }
        
        let item = UIBarButtonItem(customView: leftView)
        navigationItem.leftBarButtonItem = item
        
        // Configure table view
        tableView.register(UINib(nibName: "FPProductCartCell", bundle: nil), forCellReuseIdentifier: "productCell")
        tableView.keyboardDismissMode = .onDrag;
        tableView.separatorStyle = .none;
        tableView.backgroundColor = UIColor(red: 232.0 / 255.0, green: 232.0 / 255.0, blue: 232.0 / 255.0, alpha: 1.0)
        tableView.backgroundView = nil;
        
        // Table header view
        let headerView = UIView(frame: CGRect(x: 0.0, y: 5.0, width: 726.0, height: 86.0))
        headerView.backgroundColor = UIColor.clear
        
        categoriesBtn = UIButton(type: .custom)
        categoriesBtn.setTitle(" Main Menu", for: .normal)
        categoriesBtn.setTitleColor(UIColor.darkGray, for: .normal)
        categoriesBtn.addTarget(self, action: #selector(FPProductsAndCartViewController.displayCategories), for: .touchUpInside)
        categoriesBtn.sizeToFit()
        categoriesBtn.frame.origin = CGPoint(x: 15.0, y: 44.0)
        categoriesBtn.frame.size.height = 44.0
        categoriesBtn.isHidden = true
        headerView.addSubview(categoriesBtn)
        
        refreshBtn = UIButton(type: .custom)
        refreshBtn.setImage(UIImage(named: "refresh_btn"), for: .normal)
        refreshBtn.frame = CGRect(x: 0, y: 10.0, width: 44.0, height: 44.0);
        refreshBtn.addTarget(self, action: #selector(FPProductsAndCartViewController.refreshProductsPressed), for: .touchUpInside)
        view.addSubview(refreshBtn)
        
        searchBar = UISearchBar(frame: CGRect(x: self.refreshBtn.frame.origin.x + self.refreshBtn.frame.size.width + 5, y: 10.0, width: 657.0, height: 40.0))
        
        searchBar.isTranslucent = false
        searchBar.barTintColor = tableView.backgroundColor
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.layer.borderWidth = 1.0
        searchBar.layer.borderColor = tableView.backgroundColor!.cgColor
        
        searchBar.isHidden = true
        headerView.addSubview(searchBar)
        
        //@warning search bar deprecated
        searchTextField = UITextField(frame: searchBar.frame)
        searchTextField.autocorrectionType = UITextAutocorrectionType.no
        searchTextField.placeholder = "Search"
        searchTextField.borderStyle = UITextField.BorderStyle.none
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor.lightGray.cgColor
        searchTextField.backgroundColor = UIColor.white
        searchTextField.delegate = self
        searchTextField.enablesReturnKeyAutomatically = true
        searchTextField.returnKeyType = UIReturnKeyType.search
        searchTextField.addTarget(self, action: #selector(FPProductsAndCartViewController.searchTextFieldValueChanged(_:)), for: UIControl.Event.editingChanged)
        searchTextField.clearButtonMode = UITextField.ViewMode.whileEditing
        
        view.addSubview(searchTextField)
        
        let spacerView = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 24))
        spacerView.contentMode = UIView.ContentMode.center
        spacerView.image = UIImage(named: "search_icon")
        searchTextField.leftViewMode = UITextField.ViewMode.always
        searchTextField.leftView = spacerView
        
        headerTitleLabel = UILabel(frame: searchBar.frame)
        headerTitleLabel.backgroundColor = UIColor.clear
        headerTitleLabel.textColor = UIColor.darkGray
        headerTitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
        headerTitleLabel.text = "Select Product Category"
        headerTitleLabel.textAlignment = .center
        //headerView.addSubview(headerTitleLabel)
        
        markImageView = UIImageView(image: UIImage(named: "attention_mark"))
        markImageView.frame = CGRect(x: refreshBtn.frame.origin.x + refreshBtn.bounds.size.width / 2, y: 15.0, width: 15.0, height: 15.0)
        markImageView.contentMode = .scaleToFill
        view.addSubview(markImageView)
        
        tableView.tableHeaderView = headerView
        
        // Cart view
        cartView = FPCartView.cartViewWithFrame(cartPlaceholderView.bounds)
        cartView.delegate = self
        cartPlaceholderView.addSubview(cartView)
        
        // Categories view
        categoriesFooterView = FPProductCategoriesFooterView.productCategoriesFooterView()
        categoriesFooterView.delegate = self
        categoriesFooterPlaceholderView.addSubview(categoriesFooterView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsAndCartViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsAndCartViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.reframeForMode(true)
    }
    
    func reframeForMode(_ largeMode: Bool) {
        //UIView.animateWithDuration(0.1, animations: {
            if largeMode {
                // Show dummy search field
                //self.tableView.hidden = true
                self.searchTextField.frame = CGRect(x: 20, y: 300, width: 685, height: 58)
            } else {
                // Regular search field
                self.searchTextField.frame = self.searchBar.frame
            }
        //})
    }
    
    @objc func summaryPressed() {
        self.searchTextField.endEditing(true)
        let vc = FPCashCheckSummaryViewController.cashCheckSummaryNavigationViewControllerWithCloseBlock({[weak self] in self!.popover!.dismiss(animated: false)})
        displayPopoverInViewController(vc)
    }
    
    @objc func updateUI() {
        // Title view
        if let customer = FPCustomer.activeCustomer() {
            navigationItem.titleView = nil
            navigationItem.title = "Welcome \(customer.name). Balance: $\(FPCurrencyFormatter.printableCurrency(customer.balance))"
        } else {
            let imgView = UIImageView(image: UIImage(named: "ipad_navbar_logo"))
            imgView.frame = CGRect(x: 0.0, y: 0.0, width: imgView.image!.size.width, height: imgView.image!.size.height)
            navigationItem.titleView = imgView;
            //@todo doublecheck
            navigationItem.title = "Back"
        }
        markImageView.isHidden = (FPFarmWorker.activeWorker() == nil) || !(FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() || FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() || FPServer.sharedInstance.hasUpdates)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Drop category selected flag
        categorySelected = false
        
        if FPProduct.allProducts() == nil || (FPProduct.allProducts() != nil && FPProduct.allProducts()!.count == 0) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                self!.refreshProducts()
            }
        } else {
            products = FPProduct.allProducts()!
            displayCategories()
        }
        
        if let ao = FPOrder.activeOrder() {
            tableView.allowsSelection = ao.isPaid
        } else {
            tableView.allowsSelection = true
        }
        
        if let ac = FPCustomer.activeCustomer() {
            if ac.hasOverdueBalance && ac.overduePopoverShown {
                ac.overduePopoverShown = true
                let alert = UIAlertView()
                alert.delegate = self
                alert.tag = 2
                alert.title = "You have an overdue balance"
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Manage balance")
                alert.show()
            }
        }
        //@warning data reload added
        tableView.reloadData()
    }
    
    @objc func dismiss() {
        
        products = FPProduct.allProducts()!
        cartView.resetCart()
        FPCustomer.setActiveCustomer(nil)
        FPOrder.setActiveOrder(nil)
        cartView.headerView.checkoutBtn.setTitle("Check Out", for: .normal)
        refreshNavigationBarRightView()
        displayCategories()
        
        updateUI()
        popover!.dismiss(animated: true)
    }
    
    @objc func logoutPressed() {
        let alert = UIAlertView(title: "Are you sure you want to log out?", message: "", delegate: self, cancelButtonTitle: "No", otherButtonTitles: "Yes")
        alert.tag = 4
        alert.show()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshNavigationBarRightView()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
    }
    
    func refreshNavigationBarRightView() {
        // Navigation bar right view - Transactions, Orders, Customers, Gift Cards / Manage Balance, Edit
        var items = [UIBarButtonItem]()
        if FPFarmWorker.activeWorker() != nil {
            let inventoryItem = UIBarButtonItem(title: "Inventory", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.inventoryPressed))
            items.append(inventoryItem)
            
            let ordersItem = UIBarButtonItem(title: "Orders", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.ordersPressed))
            items.append(ordersItem)
            
            let transactionsItem = UIBarButtonItem(title: "Transactions", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.transactionsPressed))
            items.append(transactionsItem)
            
            var title = "Customers"
            if let c = FPCustomer.activeCustomer() {
                title = "Customer: " + c.name
            }
            let customersItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(FPProductsAndCartViewController.customersPressed))
            items.append(customersItem)
        } else if FPCustomer.activeCustomer() != nil {
            let manageBalanceItem = UIBarButtonItem(title: "Manage balance", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.manageBalancePressed))
            items.append(manageBalanceItem)
            if FPUser.activeUser()!.farm!.allowCustomerBalancePayments {
                let balanceItem = UIBarButtonItem(title: "Gift Cards / Balance", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.balancePressed))
                items.append(balanceItem)
            }
        }
        
        let editItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.editPressed(_:)))
        items.append(editItem)
        
        navigationItem.rightBarButtonItems = items.reversed()
    }
    
    func displayPopoverInViewController(_ vc: UIViewController) {
        let centerRect = CGRect(x:  view.frame.size.width / 2, y: view.frame.size.height / 2, width: 1, height: 1);
        self.popover = UIPopoverController(contentViewController: vc)
        popover!.delegate = self
        if let nc = vc as? UINavigationController {
            if let v = nc.viewControllers.first as? FPProductViewController {
                v.popover = popover
            }
        }
        
        popover!.present(from: centerRect, in: view, permittedArrowDirections: .init(rawValue: 0), animated: false)
    }
    
    @objc func inventoryPressed() {
        let vc = FPProductsViewController.productsViewControllerForCategory(nil, inventory: true)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func locationPressed() {
        if let rls = FPRetailLocation.allRetailLocationsNames() {
            if rls.count > 0 {
                var name = "No Location"
                if let location = FPRetailLocation.defaultLocation() {
                    name = location.name
                }
                alert = UIAlertView(title: "Retail location", message: "Current location: \(name)", delegate: self, cancelButtonTitle: "Cancel")
                alert.tag = 3
                alert.addButton(withTitle: "Change")
                alert.alertViewStyle = .plainTextInput
                let textField = alert.textField(at: 0)
                textField!.placeholder = "No location"
                var dataSource = ["No Location"]
                dataSource += rls
                textField!.inputView = FPChoiceInputView.choiceInputViewWithDataSource(dataSource,
                    completion: { [weak self] (choice: String) -> Void in
                        let textField = self!.alert.textField(at: 0)
                        textField!.text = choice
                        if textField!.text != "No Location" {
                            FPRetailLocation.makeDefault(textField!.text!)
                        } else {
                            FPRetailLocation.removeDefault()
                        }
                        self!.alert.dismiss(withClickedButtonIndex: 1, animated: true)
                })
                alert.show()
            }
        }
    }
    
    
    @objc func ordersPressed() {
        let handler = { [weak self] (order: FPOrder) -> Void in
            // Clear the cart
            self!.cartView.resetCart()
            
            // Step 1: re-authenticate the customer
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
            hud?.labelText = "Processing"
            FPServer.sharedInstance.customerAuthenticateWithPhone(order.customer.phone, pin: order.customer.pin, completion: { (errMsg: String?, customer: FPCustomer?) -> Void in
                if errMsg != nil {
                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                } else {
                    hud?.hide(false)
                    order.customer = customer!
                    FPCustomer.setActiveCustomer(order.customer)
                    
                    // Step 2: process the products
                    FPOrder.setActiveOrder(order)
                    
                    self!.navigationController!.popViewController(animated: true)
                }
            })
        }
        let vc = FPOrdersViewController.ordersViewControllerWithOrderSelectedHandler(handler)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func processOrderOrTransaction() {
        displayCategories()
    }
    
    @objc func customerAuthenticated() {
        self.products = FPProduct.allProducts()!
        self.displayCategories()
    }
    
    @objc func transactionsPressed() {
        let vc = FPTransactionsViewController.transactionsViewControllerForCustomer(nil)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func customersPressed() {
        let vc = FPCustomersViewController.customersViewController()
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func manageBalancePressed() {
        let viewController = FPCustomerManageBalanceViewController()
        viewController.cancelTapped = { [weak self] in
            self?.popover?.dismiss(animated: false)
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        displayPopoverInViewController(navigationController)
    }
    
    @objc func balancePressed() {
        self.searchTextField.endEditing(true)
        let vc = FPGiftCardOptionsViewController.giftCardOptionsNavigationViewControllerWithCloseBlock({[weak self] in self!.popover!.dismiss(animated: false)})
        displayPopoverInViewController(vc)
    }
    
    @objc func editPressed(_ sender: UIBarButtonItem) {
        self.searchTextField.endEditing(true)
        cartView.tableView.setEditing(!cartView.tableView.isEditing, animated: true)
        sender.title = cartView.tableView.isEditing ? "Done" : "Edit"
    }
    
    @objc func refreshProductsPressed() {
        if FPFarmWorker.activeWorker() != nil {
            let alert = UIAlertView()
            alert.tag = 1
            alert.delegate = self
            alert.title = "Choose option"
//            var hasUnsyncedPayments = false
//            var hasUnsyncedCustomers = false
            var message = ""
            if FPDataAccessLayer.sharedInstance.hasUnsyncedPurchases() {
                message = "Number of unsynced payments: \(FPDataAccessLayer.sharedInstance.unsyncedPurchases().count)"
            }
            if FPDataAccessLayer.sharedInstance.hasUnsyncedCustomers() {
                message = message + "\nNumber of unsynced customers: \(FPDataAccessLayer.sharedInstance.unsyncedCustomers().count)"
            }
            alert.message = message
            alert.addButton(withTitle: "Synchronize")
            //            alert.addButtonWithTitle("Refresh products")
            alert.addButton(withTitle: "Resolve sync issues")
            alert.addButton(withTitle: "Cancel")
            alert.show()
        } else {
            refreshProducts()
        }
    }
    
    func refreshProducts() {
        var hud: MBProgressHUD!
        
        FPSyncManager.sharedInstance.syncWithCompletion { [weak self] in
            
            if self == nil {
                hud.hide(false)
                return
            }
            
            if let ac = FPCustomer.activeCustomer() {
                
                hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud.removeFromSuperViewOnHide = true
                hud.labelText = "Finishing up"
                
                FPServer.sharedInstance.customerAuthenticateWithPhone(ac.phone, pin: ac.pin, completion: {
                    errMsg, customer in
                    hud.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    } else if customer != nil {
                        FPCustomer.setActiveCustomer(customer)
                        self!.products = FPProduct.allProducts()!
                        self!.displayCategories()
                    }
                })
            } else {
                if let p = FPProduct.allProducts() {
                    self!.products = p
                    self!.displayCategories()
                }
            }
            
            self!.updateUI()
        }
    }
    
    @objc func displayCategories() {
        sectionsBackup = [Dictionary<String, AnyObject>]()
//        showingCategories = true
        view.endEditing(true)
        searchBar.text = ""
        //searchBar.hidden = true;
        categoriesBtn.isHidden = true
        tableView.tableHeaderView!.frame.size.height = 44.0
        tableView.tableHeaderView = tableView.tableHeaderView
        headerTitleLabel.isHidden = false
        
        var categories = [NSDictionary]()
        
        let cSet = NSMutableSet()
        for product in products {
            cSet.add(product.category.name)
        }
        
        for category in cSet.allObjects as! Array<String> {
            var p: FPProduct?
            for product in products.reversed() {
                if product.category.name == category {
                    if p == nil || p?.imageURL == nil {
                        p = product
                    }
                    if p?.imageURL != nil {
                        break
                    }
                }
            }
            categories.append(["name": category, "product": p!])
        }
        
        categories.sort { (d1, d2) -> Bool in
            let name1 = d1["name"] as! String
            let name2 = d2["name"] as! String
            return name1.lowercased() < name2.lowercased()
        }
        
        sections = [["items": categories as AnyObject]]
        
        categoriesFooterView.categories = categories
        // Disabled selection of first category by default for FL-77
        
//        if (categories.count > 0) {
//            self.selectCategory(categories.first!)
//        }
//        tableView.reloadData()
    }
    
    func sortProducts(_ products: [FPProduct]) -> [FPProduct] {
        let sortDescriptors = [NSSortDescriptor(key: "onSaleNow", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
        let p = (products as NSArray).sortedArray(using: sortDescriptors) as! [FPProduct]
        return p
    }
    
    // UITableView delegate and data source
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 230.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height: CGFloat = 0.0
        if !showingCategories && sections.count > 1 {
            height = 44.0
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if showingCategories {
            return nil
        }
        
        let headerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width, height: 44.0))
        headerView.backgroundColor = UIColor.clear
        
        let label = UILabel(frame: headerView.bounds.offsetBy(dx: 15.0, dy: 0.0))
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.darkGray
        label.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
        
        if let text = sections[section]["section"] as? NSString {
            label.text = text as String
        }
        headerView.addSubview(label)
        return headerView
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Waiting for dem apple fixes
        if numberOfSections(in: tableView) < section + 1 {
            return 0
        }
        if categorySelected {
            let resultArray = sections[section]["items"] as! NSArray
            return resultArray.count / 3 + (resultArray.count % 3 > 0 ? 1 : 0);
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "productCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? FPProductCartCell
        cell!.backgroundColor = UIColor.clear // workaround
        let items = sections[indexPath.section]["items"] as! NSArray
        var ps = [AnyObject]()
        let idx = indexPath.row * 3
        var i = idx
        while i < idx + 3 && i < items.count {
            ps.append(items[i] as AnyObject)
            i += 1
        }
        cell!.delegate = self
        cell!.objects = ps
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: false)
    }
    
    func selectCategory(_ ci: NSDictionary) {
        categorySelected = true
        var s = [Dictionary<String, AnyObject>]()
        self.tableView.contentOffset = CGPoint(x: 0, y: 0)
        showingCategories = false
        headerTitleLabel.isHidden = true
        let category = ci["name"] as! String
        
        let p = products.filter({
            if $0.category.name == category {
                return true
            }
            return false
        })
        s.append(["section" : "" as AnyObject, "items" : sortProducts(p) as AnyObject])
        
        sections = s
        tableView.reloadData()
    }
    
    // FPProductCartCell delegate
    func productCartCellDidSelect(_ cell: FPProductCartCell, object: AnyObject)  {
        // Hide keyboard for all search scenarios
        self.searchTextField.resignFirstResponder()
        if let ci = object as? NSDictionary { // Category selected
            self.selectCategory(ci)
        } else if let product = object as? FPProduct {
            if product.onSaleNow {
                // Add to cart
//                var cartProduct = cartView.cartProductWithProduct(product)
//                var updating = true
//                if cartProduct == nil {
//                    updating = false
//                    cartProduct = FPCartProduct(product: product)
//                }
                
                let cartProduct: FPCartProduct? = FPCartProduct(product: product)
                let updating = false
                let vc = FPProductViewController.productNavigationViewControllerForCartProduct(cartProduct!, delegate: self, updating: updating)
                displayPopoverInViewController(vc)
            }
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        //
        self.reframeForMode(true)
        //self.searchBar.resignFirstResponder()
        //self.searchTextField.becomeFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == self.searchTextField {
            textField.text = ""
            categorySelected = true
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        searchBar.text = textField.text
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTextField.resignFirstResponder()
        return true
    }
    
    // UISearchBar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText as NSString).length == 0 {
            sections = sectionsBackup
            sectionsBackup = [Dictionary<String, AnyObject>]()
        } else {
            if sectionsBackup.count == 0 {
                sectionsBackup = sections
            }
            
            sections = [Dictionary<String, AnyObject>]()
            
            var s = [Dictionary<String, AnyObject>]()
            
            let p = products
            if p.count > 0 {
                s.append(["section": "" as AnyObject, "items": sortProducts(p) as AnyObject])
            }
            
            for sectionInfo in s {
                var sInfo = sectionInfo
                var ps = sInfo["items"] as! [AnyObject]
                let predicate = NSPredicate(format: "name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@", searchText, " \(searchText)", searchText)
                ps = ps.filter({ (obj) -> Bool in
                    return predicate.evaluate(with: obj)
                })
//                ps = (ps as! NSArray).filteredArrayUsingPredicate(NSPredicate(format: "name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@", searchText, " \(searchText)", searchText)!)
                sInfo["items"] = ps as AnyObject?
                if ps.count > 0 {
                    sections.append(sInfo)
                }
            }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        //searchBar.text = ""
    }
    
    // FPCartView delegate
    func cartViewDidCheckout(_ cartView: FPCartView) {
        if cartView.cartProducts.count > 0 {
            let vc = FPCheckoutViewController.checkoutViewController()
            navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    func cartViewDidDeleteProduct(_ cartView: FPCartView) {
        tableView.reloadData()
    }
    
    func cartViewDidReset(_ cartView: FPCartView) {
        refreshNavigationBarRightView()
        if let ap = FPProduct.allProducts() {
            products = ap
            displayCategories()
        }
    }
    
    func cartViewDidSelectProduct(_ cartView: FPCartView, p: FPCartProduct) {
        self.searchTextField.endEditing(true)
        let vc = FPProductViewController.productNavigationViewControllerForCartProduct(p, delegate: self, updating: true)
        displayPopoverInViewController(vc)
    }
    
    // Popover delegate
    func popoverControllerShouldDismissPopover(_ popoverController: UIPopoverController) -> Bool {
        return false
    }
    
    // ProductViewController delegate
    func productViewControllerDidAdd(_ pvc: FPProductViewController, cartProduct: FPCartProduct) {
        cartView.addCartProduct(cartProduct, updating: pvc.updating)
        tableView.reloadData()
        popover!.dismiss(animated: true)
    }
    
    func productViewControllerDidRemove(_ pvc: FPProductViewController, cartProduct: FPCartProduct) {
        cartView.deleteCartProduct(cartProduct)
        tableView.reloadData()
        popover!.dismiss(animated: true)
    }
    
    func productViewControllerDidCancel(_ pvc: FPProductViewController) {
        popover!.dismiss(animated: true)
    }
    
    // UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.tag == 1 {
            if buttonIndex == 0 {
                if !FPServer.sharedInstance.reachabilityManager.isReachable {
                    return
                }
                
                products = FPProduct.allProducts()!
                cartView.resetCart()
                FPOrder.setActiveOrder(nil)
                var title = "Check Out"
                if FPOrder.activeOrder() != nil {
                    title = "Fulfill"
                }
                cartView.headerView.checkoutBtn.setTitle(title, for: .normal)
                refreshNavigationBarRightView()
                displayCategories()
                
                var hud: MBProgressHUD!
                
                FPSyncManager.sharedInstance.syncWithCompletion { [weak self] in
                    
                    if let ac = FPCustomer.activeCustomer() {
                        
                        hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                        hud.removeFromSuperViewOnHide = true
                        hud.labelText = "Finishing up"
                        
                        FPServer.sharedInstance.customerAuthenticateWithPhone(ac.phone, pin: ac.pin, completion: {
                            errMsg, customer in
                            hud.hide(false)
                            if errMsg != nil {
                                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                            } else {
                                FPCustomer.setActiveCustomer(customer)
                                self!.products = FPProduct.allProducts()!
                                self!.displayCategories()
                            }
                        })
                    } else {
                        self!.products = FPProduct.allProducts()!
                        self!.displayCategories()
                    }
                    
                    self!.updateUI()
                }
            } else if buttonIndex == 1 {
                let vc = FPUnsyncedItemsTableViewController.unsyncedItemsTableViewController()
                let nc = UINavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.dismiss as (FPProductsAndCartViewController) -> () -> ()))
                nc.navigationBar.isTranslucent = false
                nc.navigationBar.barStyle = .black
                nc.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
                displayPopoverInViewController(nc)
            }
        }
        else if alertView.tag == 2 {
            if buttonIndex == 1 {
                let vc = FPManageBalanceViewController.manageBalanceViewControllerWithCompletion({[weak self] in self!.popover!.dismiss(animated: true)})
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPProductsAndCartViewController.dismiss as (FPProductsAndCartViewController) -> () -> ()))
                let nc = UINavigationController(rootViewController: vc)
                nc.navigationBar.isTranslucent = false
                nc.navigationBar.barStyle = .black
                nc.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
                
                displayPopoverInViewController(nc)
            }
        }
        else if alertView.tag == 3 {
            if buttonIndex == 1 {
                let textField = alert.textField(at: 0)!
                if textField.text != "No Location" {
                    FPRetailLocation.makeDefault(textField.text!)
                } else {
                    FPRetailLocation.removeDefault()
                }
            }
        }
        else if alertView.tag == 4 {
            if buttonIndex == 1 {
                if let fw = FPFarmWorker.activeWorker() {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: FPUserLoginStatusChanged), object: ["status": FPLoginStatus.loggedOut.rawValue, "user": fw], userInfo: nil)
                } else {
                    let appDelegate = UIApplication.shared.delegate as! FPAppDelegate
                    appDelegate.customerLoggedOut()
                }
            }
        }
    }
    
    @objc func searchTextFieldValueChanged(_ textfield : UITextField) {
        if (textfield.text! as NSString).length == 0 {
            sections = sectionsBackup
            sectionsBackup = [Dictionary<String, AnyObject>]()
        } else {
            if sectionsBackup.count == 0 {
                sectionsBackup = sections
            }
            
            sections = [Dictionary<String, AnyObject>]()
            
            var s = [Dictionary<String, AnyObject>]()
            s.append(["section" : "" as AnyObject, "items" : sortProducts(products) as AnyObject])
            
            for sectionInfo in s {
                var sInfo = sectionInfo
                var ps = sInfo["items"] as! [AnyObject]
                let predicate = NSPredicate(format: "name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@", textfield.text!, " \(textfield.text!)", textfield.text!)
                ps = ps.filter({ (obj) -> Bool in
                    return predicate.evaluate(with: obj)
                })
                //                ps = (ps as! NSArray).filteredArrayUsingPredicate(NSPredicate(format: "name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@", searchText, " \(searchText)", searchText)!)
                sInfo["items"] = ps as AnyObject?
                if ps.count > 0 {
                    sections.append(sInfo)
                }
            }
        }
        tableView.reloadData()
    }
    
    // MARK: - FPProductCategoriesFooterViewDelegate
    func productCategoriesFooterView(_ footerView: FPProductCategoriesFooterView, didSelectCategory category: NSDictionary) {
        self.selectCategory(category)
        self.reframeForMode(false)
    }
    
    @objc func keyboardWillChangeFrame(_ note: NSNotification) {
        if let kbRect = (note.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            reframeForMode(true)
            UIView.animate(withDuration: 0.2, animations: {
//                var val :CGFloat = kbRect.origin.y - self.searchTextField.frame.height
                self.searchTextField.frame = CGRect(x: self.searchTextField.frame.origin.x, y: kbRect.origin.y - 58 * 2 - 6, width: self.searchTextField.frame.width, height: 58)
            })
        }
    }
    
    @objc func keyboardWillHide(_ note: NSNotification) {
        //self.setScrollViewInsets(UIEdgeInsetsZero)
        self.reframeForMode(false)
    }
}
