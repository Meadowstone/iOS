//
//  FPInventoryProductHistoryViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 30/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD
import SVPullToRefresh

class FPInventoryProductHistoryViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var page: Int = 1
    var historyItems = [FPInventoryProductHistory]()
    var dateFormatter: DateFormatter!
    var product: FPProduct!
    
    class func inventoryProductHistoryViewControllerForProduct(_ product: FPProduct) -> FPInventoryProductHistoryViewController {
        let vc = FPInventoryProductHistoryViewController()
        vc.product = product
        return vc
    }
    
    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        
        self.tableView = UITableView()
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(self.tableView)
        
        var tableViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: ["tableView": self.tableView])
        tableViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: ["tableView": self.tableView])
        self.view.addConstraints(tableViewConstraints)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Inventory History"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(FPInventoryProductHistoryViewController.resetPressed(_:)))
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MM/dd/yyyy hh:mm a"
        
        self.tableView.addInfiniteScrolling { [weak self] in
            self?.fetchHistoryItems()
        }
        
        self.tableView.triggerInfiniteScrolling()
    }
    
    @objc func resetPressed(_ btn: UIBarButtonItem) {
        let alert = UIAlertController(title: "Warning", message: "You are about to reset this product's inventory. Are you sure you want to reset?", preferredStyle: UIAlertController.Style.actionSheet)
        alert.popoverPresentationController?.barButtonItem = btn
        alert.popoverPresentationController?.sourceView = self.view
        alert.addAction(UIAlertAction(title: "Reset", style: UIAlertAction.Style.destructive, handler: { (action) -> Void in
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
            hud?.labelText = "Processing"
            FPServer.sharedInstance.inventoryHistoryDelete(nil, product: self.product, completion: { (errMsg, product) -> Void in
                hud?.hide(false)
                if let e = errMsg {
                    FPAlertManager.showMessage(e, withTitle: "Error")
                } else {
                    if let p = product {
                        self.product.mergeWithProduct(p)
                    }
                    self.historyItems.removeAll(keepingCapacity: false)
                    self.tableView.reloadData()
                    _ = self.navigationController?.popViewController(animated: true)
                }
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { (action) -> Void in
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func fetchHistoryItems() {
        FPServer.sharedInstance.inventoryProductHistoryItemsForPage(page, product: self.product, completion: { (errMsg, historyItems, nextPage) -> Void in
            self.tableView.infiniteScrollingView.stopAnimating()
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else if let items = historyItems {
                self.historyItems += items
                self.page = nextPage!
            }
            self.tableView.showsInfiniteScrolling = self.page != -1
            self.tableView.reloadData()
        })
    }
    
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell?.selectionStyle = .none
        }
        let historyItem = self.historyItems[indexPath.row]
        cell!.textLabel?.text = "Amount: \(historyItem.amount)"
        cell!.detailTextLabel?.text = "Date: \(self.dateFormatter.string(from: historyItem.dateCreated))"
        return cell!
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
            hud?.labelText = "Processing"
            FPServer.sharedInstance.inventoryHistoryDelete(self.historyItems[indexPath.row], product: self.product, completion: { (errMsg, product) -> Void in
                hud?.hide(false)
                if let e = errMsg {
                    FPAlertManager.showMessage(e, withTitle: "Error")
                } else {
                    if let p = product {
                        self.product.mergeWithProduct(p)
                    }
                    self.historyItems.remove(at: indexPath.row)
                    self.tableView.reloadData()
                }
            })
        }
    }
}
