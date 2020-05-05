//
//  FPTransactionsViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/17/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import QuickLook
import SVPullToRefresh
import MBProgressHUD

class FPTransactionsViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, FPTransactionCellDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource {
    
    var customer: FPCustomer?
    var dataTask: URLSessionDataTask?
    var filterDate: Date?
    var page: Int = 1
    var receiptPath: String?
    var transactions = [FPTransaction]()
    var tableView: UITableView!
    
    class func transactionsViewControllerForCustomer(_ c: FPCustomer?) -> FPTransactionsViewController {
        let vc = FPTransactionsViewController()
        vc.customer = c
        return vc
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        if let c = customer {
            navigationItem.title = "\(c.name): Transactions"
        } else {
            let fs = UISegmentedControl(items: ["All", "Today"])
            fs.selectedSegmentIndex = 0
            fs.frame = CGRect(x: 0.0, y: 0.0, width: 200.0, height: fs.frame.size.height)
            fs.addTarget(self, action: #selector(FPTransactionsViewController.filterChanged(_:)), for: .valueChanged)
            navigationItem.titleView = fs
        }
        
        tableView = UITableView(frame: view.bounds)
        view.addSubview(tableView)
        tableView.register(UINib(nibName: "FPTransactionCell", bundle: nil), forCellReuseIdentifier: "FPTransactionCell")
        tableView.separatorColor = UINavigationBar.appearance().barTintColor
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = self
        tableView.dataSource = self
        
        let handler = { [weak self] () -> Void in
            let completion = { (errMsg: String?, transactions: Array<FPTransaction>?, nextPage: Int?) -> Void in
                if self == nil {
                    return
                }
                self!.tableView.infiniteScrollingView.stopAnimating()
                if errMsg != nil {
                    FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                } else {
                    self!.page = nextPage!
                    self!.transactions += transactions!
                    self!.tableView.showsInfiniteScrolling = nextPage != -1
                    self!.tableView.reloadData()
                }
            }
            self!.dataTask?.cancel()
            self!.dataTask = FPServer.sharedInstance.transactionsForDate(self!.filterDate, customer: self!.customer, page: self!.page, completion: completion)
        }
        
        tableView.addInfiniteScrolling(actionHandler: handler)
        tableView.triggerInfiniteScrolling()
    }
    
    @objc func filterChanged(_ fs: UISegmentedControl) {
        if fs.selectedSegmentIndex == 0 {
            filterDate = nil
        } else {
            filterDate = Date()
        }
        transactions = [FPTransaction]()
        tableView.reloadData()
        tableView.infiniteScrollingView.stopAnimating()
        tableView.showsInfiniteScrolling = true
        page = 1
        tableView.triggerInfiniteScrolling()
    }
    
    // UITableView delegate & data source
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return FPTransactionCell.cellHeightForTransaction(transactions[indexPath.row], hideVoidBtn: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPTransactionCell") as! FPTransactionCell
        cell.setTransaction(transactions[indexPath.row], hideVoidBtn: false)
        cell.delegate = self
        return cell
    }
    
    // MARK: - FPTransactionCell delegate
    func transactionCellDidPressVoid(_ cell: FPTransactionCell) {
        var hud: MBProgressHUD!
        let completion = { [weak self] (errMsg: String?) -> Void in
            hud.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: FPTransactionOrOrderProcessingNotification), object: nil)
                if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                    self!.navigationController!.popToRootViewController(animated: true)
                } else {
                    FPMenuViewController.instance().redirectToCart()
                }
            }
        }
        hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud.removeFromSuperViewOnHide = true
        hud.labelText = "Processing"
        FPServer.sharedInstance.voidTransaction(cell.transaction, completion: completion)
    }
    
    func transactionCellDidPressReceipt(_ cell: FPTransactionCell) {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Processing"
        hud?.detailsLabelText = "Retrieving receipt URL"
        FPServer.sharedInstance.receiptForTransaction(cell.transaction, completion: { (errMsg, pdfURL) -> Void in
            if let errors = errMsg {
                hud?.hide(false)
                FPAlertManager.showMessage(errors, withTitle: "Error")
            } else {
                FPServer.sharedInstance.downloadFileWithURL(pdfURL!, completion: { (errors, path) -> Void in
                    hud?.hide(false)
                    if let e = errors {
                        FPAlertManager.showMessage(e, withTitle: "Error")
                    } else {
                        self.receiptPath = path
                        let vc = QLPreviewController()
                        vc.delegate = self
                        vc.dataSource = self
                        self.present(vc, animated: true, completion: nil)
                    }
                }, progress: { (progress) -> Void in
                    hud?.progress = progress
                    hud?.detailsLabelText = "Downloading receipt"
                })
            }
        })
    }
    
    // MARK: - QLPreviewController
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        var receiptURL: URL!
        if let receiptPath = self.receiptPath {
            receiptURL = URL(fileURLWithPath: receiptPath)
        }
        return receiptURL as QLPreviewItem!
    }
}
