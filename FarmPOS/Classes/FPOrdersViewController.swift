//
//  FPOrdersViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/16/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import SVPullToRefresh
import MBProgressHUD

class FPOrdersViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, FPOrderCellDelegate {
    
    var cancelingOrder: FPOrder?
    var orderSelectedHandler: ((FPOrder) -> Void)!
    var dataTask: URLSessionDataTask?
    var filterDate: Date?
    var page: Int = 1
    var orders = [FPOrder]()
    var tableView: UITableView!
    
    // When FPOrder is selected two actions have to be performed: 1) order.customer must be set to active
    // 2) order.productsInfo must be processed to repopulate current products CSA information and limits.
    class func ordersViewControllerWithOrderSelectedHandler(_ osh: @escaping (FPOrder) -> Void) -> FPOrdersViewController {
        let vc = FPOrdersViewController()
        vc.orderSelectedHandler = osh
        return vc
    }
    
    deinit {
        dataTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fs = UISegmentedControl(items: ["All", "Today"])
        fs.selectedSegmentIndex = 0
        fs.frame = CGRect(x: 0.0, y: 0.0, width: 200.0, height: fs.frame.size.height)
        fs.addTarget(self, action: #selector(FPOrdersViewController.filterChanged(_:)), for: .valueChanged)
        navigationItem.titleView = fs
        
        tableView = UITableView(frame: view.bounds)
        tableView.register(UINib(nibName: "FPOrderCell", bundle: nil), forCellReuseIdentifier: "FPOrderCell")
        tableView.separatorColor = UINavigationBar.appearance().barTintColor
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        
        let handler = { [weak self] () -> Void in
            let completion = { (errMsg: String?, orders: Array<FPOrder>?, nextPage: Int?) -> Void in
                if self == nil {
                    return
                }
                self!.tableView.infiniteScrollingView.stopAnimating()
                if errMsg != nil {
                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                } else {
                    self!.page = nextPage!
                    self!.orders += orders!
                    self!.tableView.showsInfiniteScrolling = nextPage != -1
                    self!.tableView.reloadData()
                }
            }
            self!.dataTask?.cancel()
            self!.dataTask = FPServer.sharedInstance.ordersForDate(self!.filterDate, page: self!.page, completion: completion)
        }
        tableView.addInfiniteScrolling(actionHandler:handler)
        tableView.triggerInfiniteScrolling()
        
        view.addSubview(tableView)
    }
    
    @objc func filterChanged(_ fs: UISegmentedControl) {
        if fs.selectedSegmentIndex == 0 {
            filterDate = nil
        } else {
            filterDate = Date()
        }
        orders = [FPOrder]()
        tableView.reloadData()
        tableView.infiniteScrollingView.stopAnimating()
        tableView.showsInfiniteScrolling = true
        page = 1
        tableView.triggerInfiniteScrolling()
    }
    
    // UITableView delegate & data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FPOrderCell.cellHeightForOrder(orders[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPOrderCell") as! FPOrderCell
        cell.bounds = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: cell.bounds.size.height)
        cell.delegate = self;
        cell.order = orders[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        orderSelectedHandler(orders[indexPath.row])
    }
    
    // FPOrderCell delegate
    func orderCellDidPressCancel(_ cell: FPOrderCell) {
        cancelingOrder = cell.order
        let alert = UIAlertView()
        alert.delegate = self
        alert.title = "Are you sure you want to cancel this order?"
        alert.addButton(withTitle:"Yes, cancel")
        alert.addButton(withTitle:"No, don't cancel")
        alert.show()
    }
    
    // UIAlertView delegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if buttonIndex == 0 {
            var hud: MBProgressHUD!
            let completion = { [weak self] (errMsg: String?) -> Void in
                hud.hide(false)
                if errMsg != nil {
                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                } else {
                    if let idx = self!.orders.index(of: self!.cancelingOrder!) {
                        self!.orders.remove(at: idx)
                        self!.cancelingOrder = nil
                        self!.tableView.reloadData()
                    }
                }
            }
            hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud.removeFromSuperViewOnHide = true
            hud.labelText = "Canceling order"
            FPServer.sharedInstance.orderCancel(cancelingOrder!, completion: completion)
        }
    }
    
}
