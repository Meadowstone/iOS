//
//  FPTriggerAlertsViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 24/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import SVPullToRefresh

class FPTriggerAlertsViewController: FPRotationViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var page: Int = 1
    var alerts = [FPTriggerAlert]()
    var dateFormatter: DateFormatter!
    
    class func triggerAlertsViewController() -> FPTriggerAlertsViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FPTriggerAlertsViewController") as! FPTriggerAlertsViewController
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Notifications"
        
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MM/dd/yyyy hh:mm a"
        
        self.tableView.addInfiniteScrolling { [weak self] in
            self?.fetchAlerts()
        }
        
        self.tableView.triggerInfiniteScrolling()
    }
    
    func fetchAlerts() {
        FPServer.sharedInstance.triggerAlertsForPage(page, completion: { (errMsg, alerts, nextPage) -> Void in
            self.tableView.infiniteScrollingView.stopAnimating()
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else if let a = alerts {
                self.alerts += a
                self.page = nextPage!
            }
            self.tableView.showsInfiniteScrolling = self.page != -1
            self.tableView.reloadData()
        })
    }
    
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alerts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        }
        let alert = alerts[indexPath.row]
        cell?.textLabel?.text = "\(alert.product.name)"
        cell?.detailTextLabel?.text = "Trigger amount: \(alert.triggerAmount). Date: \(self.dateFormatter.string(from: alert.date))"
        return cell!
    }
    
}
