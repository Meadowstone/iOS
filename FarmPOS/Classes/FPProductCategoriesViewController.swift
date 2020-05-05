//
//  FPProductCategoriesViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductCategoriesViewController: FPRotationTableViewController {
    
    var categories = [FPProductCategory]()
    var categorySelectedHandler: ((FPProductCategory) -> Void)!
    
    
    class func productCategoriesViewControllerWithCategorySelectedHandler(_ handler: @escaping (_ category: FPProductCategory) -> Void) -> FPProductCategoriesViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FPProductCategoriesViewController") as! FPProductCategoriesViewController
        vc.categorySelectedHandler = handler
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select category"
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(FPProductCategoriesViewController.refreshCategories), for: .valueChanged)
        refreshControl!.beginRefreshing()
        tableView.contentOffset = CGPoint(x: 0.0, y: 0.0)
        refreshCategories()
        
    }
    
    @objc func refreshCategories() {
        FPServer.sharedInstance.productCategoriesWithCompletion({
            [weak self] errMsg, categories in
            if self == nil {
                return
            }
            self!.refreshControl!.endRefreshing()
            if errMsg != nil {
                self!.refreshControl!.attributedTitle = NSAttributedString(string: "Unable to sync with server. Pull to refresh.")
            } else {
                self!.refreshControl!.attributedTitle = nil
                self!.categories = categories!
                self!.tableView.reloadData()
            }
        })
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell!.textLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 17.0)
            cell!.textLabel!.textColor = UIColor.darkGray
        }
        cell!.textLabel!.text = categories[indexPath.row].name
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        categorySelectedHandler(categories[indexPath.row])
    }

}
