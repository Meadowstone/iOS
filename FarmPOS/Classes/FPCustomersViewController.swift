//
//  FPCustomersViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/17/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD
import SVPullToRefresh

class FPCustomersViewController: FPRotationViewController, UIPopoverControllerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FPCustomerCellDelegate, UITextFieldDelegate {
    
    var popover: UIPopoverController?
    var searchBar: UISearchBar!
    var tableView: UITableView!
    var customers = [FPCustomer]()
    var page = 1
    var didSearch = false
    
    var fromLoad = false
    
    class func customersViewController() -> FPCustomersViewController {
        let vc = FPCustomersViewController()
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fromLoad = true
        
        navigationItem.title = "Customers"
        
        var items = [UIBarButtonItem(title: "New Customer", style: .plain, target: self, action: #selector(FPCustomersViewController.addCustomerPressed))]
        if FPCustomer.activeCustomer() != nil && UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            items.append(UIBarButtonItem(title: "\(FPCustomer.activeCustomer()!.name) - Unassign", style: .plain, target: self, action: #selector(FPCustomersViewController.unassign)))
        }
        navigationItem.rightBarButtonItems = items
        
        // Table view
        tableView = UITableView(frame: view.bounds)
        tableView.register(UINib(nibName: "FPCustomerCell", bundle: nil), forCellReuseIdentifier: "FPCustomerCell")
        tableView.keyboardDismissMode = .onDrag
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.separatorColor = UINavigationBar.appearance().barTintColor
        tableView.backgroundColor = UIColor(red: 232.0 / 255.0, green: 232.0 / 255.0, blue: 232.0 / 255.0, alpha: 1.0)
        tableView.backgroundView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.addInfiniteScrolling { [weak self] in
            self!.loadMoreItems()
        }
        view.addSubview(tableView)
        
        // Search bar
        let sb = UISearchBar(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.size.width, height: 44.0))
        sb.autoresizingMask = .flexibleWidth
        sb.delegate = self
        sb.isTranslucent = false
        sb.barTintColor = tableView.backgroundColor
        sb.layer.borderWidth = 1
        sb.layer.borderColor = tableView.backgroundColor!.cgColor
        sb.placeholder = "Search"
        searchBar = sb
        tableView.tableHeaderView = sb
        
        self.reloadContent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if fromLoad {
            searchBar.becomeFirstResponder()
            fromLoad = false
        }
    }
    
    func loadMoreItems() {
        if searchBar.text!.count == 0 {
            tableView.infiniteScrollingView.stopAnimating()
            return
        }
        let searchText = didSearch ? searchBar.text : ""
        let completion = { [weak self] (errMsg: String?, customers: [FPCustomer]?, nextPage: Int?) -> Void in
            if self == nil {
                return
            }
            self!.tableView.infiniteScrollingView.stopAnimating()
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self!.customers += customers!
                self!.page = nextPage!
                self!.tableView.reloadData()
                self!.tableView.showsInfiniteScrolling = nextPage! != -1
            }
        }
        FPServer.sharedInstance.customersForPage(page, searchQuery: searchText!, completion: completion)
    }
    
    func reloadContent() {
        customers = [FPCustomer]()
        page = 1
        view.endEditing(true)
        tableView.reloadData()
        tableView.showsInfiniteScrolling = true
        tableView.triggerInfiniteScrolling()
    }
    
    func dismiss() {
        FPCustomer.setActiveCustomer(nil)
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            self.popover!.dismiss(animated: false)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func unassign() {
        FPCardFlightManager.sharedInstance.cardFlightCard = nil
        FPCustomer.setActiveCustomer(nil)
        FPOrder.setActiveOrder(nil)
        FPCartView.sharedCart().resetCart()
        navigationController!.popViewController(animated: true)
    }
    
    func addCustomerPressed() {
        searchBar.endEditing(true)
        let completion = { [weak self] (customer: FPCustomer?) -> Void in
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                self!.popover!.dismiss(animated: false)
            } else {
                self!.navigationController!.popViewController(animated: true)
            }
            if let c = customer {
                self!.customerSelected(c)
            }
        }
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            let centerRect = CGRect(x: view.frame.size.width / 2, y: view.frame.size.height / 2, width: 1, height: 1);
            let vc = FPAccountSetupViewController.accountSetupViewControllerWithCompletion(completion)
            let nc = UINavigationController(rootViewController: vc)
            popover = UIPopoverController(contentViewController: nc)
            popover!.delegate = self
            popover!.present(from: centerRect, in: view, permittedArrowDirections: UIPopoverArrowDirection(rawValue: 0), animated: false)
        } else {
            let vc = FPCustomerCreateViewController.customerCreateViewControllerWithCompletion(completion)
            navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    func customerSelected(_ customer: FPCustomer) {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Processing"
        FPServer.sharedInstance.customerAuthenticateWithPhone(customer.phone, pin: customer.pin, completion: {[weak self] (errMsg: String?, customer: FPCustomer?) -> Void in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                FPOrder.setActiveOrder(nil)
                FPCartView.sharedCart().resetCart()
                FPCustomer.setActiveCustomer(customer)
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPCustomerAuthenticatedNotification), object: nil)
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    self!.navigationController!.popViewController(animated: true)
                } else {
                    FPMenuViewController.instance().redirectToCart()
                }
            }
        })
    }
    
    // SearchBar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText as NSString).length == 0 {
            didSearch = false
            reloadContent()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        didSearch = true
        reloadContent()
    }
    
    // Popover delegate
    func popoverControllerShouldDismissPopover(_ popoverController: UIPopoverController) -> Bool {
        return false
    }
    
    // UITableView delegate & data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FPCustomerCell.cellHeightForCustomer(customers[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return customers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPCustomerCell") as! FPCustomerCell
        cell.delegate = self
        cell.customer = customers[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        customerSelected(customers[indexPath.row])
    }
    
    // CustomerCell delegate
    func customerCellDidPressTransactions(_ cell: FPCustomerCell) {
        let vc = FPTransactionsViewController.transactionsViewControllerForCustomer(cell.customer)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    func customerCellDidPressBalance(_ cell: FPCustomerCell) {
        
        let completion = { [weak self] () -> Void in
            FPCustomer.setActiveCustomer(nil)
            self!.tableView.reloadData()
            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                self!.popover!.dismiss(animated: false)
            } else {
                self!.dismiss(animated: true, completion: nil)
            }
        }
        
        FPCustomer.setActiveCustomer(cell.customer)
        
        let vc = FPManageBalanceViewController.manageBalanceViewControllerWithCompletion(completion)
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPCustomersViewController.dismiss as (FPCustomersViewController) -> () -> ()))
        let nc = UINavigationController(rootViewController: vc)
        nc.navigationBar.isTranslucent = false
        nc.navigationBar.barStyle = .black
        nc.navigationBar.barTintColor = UINavigationBar.appearance().barTintColor
        
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            let centerRect = CGRect(x: view.frame.size.width / 2, y: view.frame.size.height / 2, width: 1, height: 1);
            popover = UIPopoverController(contentViewController: nc)
            popover!.delegate = self
            popover!.present(from: centerRect, in: view, permittedArrowDirections: UIPopoverArrowDirection(rawValue: 0), animated: false)
        } else {
            present(nc, animated: true, completion: nil)
        }
    }
    
    func customerCellDidPressEdit(_ cell: FPCustomerCell) {
        let vc = FPCustomerEditViewController.customerEditViewControllerForCustomer(cell.customer, completion: { (customer, cancelled) -> Void in
            if !cancelled {
                if let indexPath = self.tableView.indexPath(for: cell) {
                    self.customers[indexPath.row] = customer!
                }
                cell.customer = customer
            }
            self.dismiss(animated: true, completion: nil)
        })
        let nc = UINavigationController(rootViewController: vc)
        self.present(nc, animated: true, completion: nil)
    }
    
}
