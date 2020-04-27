//
//  FPSelectNamableViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 28/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPSelectNamableViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var navigationBarTitle = ""
    var dataSource = [FPNamable]()
    var objectSelectedHandler: ((_ object: FPNamable) -> Void)!
    
    class func selectNamableViewControllerWithDataSource(_ dataSource: [FPNamable], navigationBarTitle: String, objectSelectedHandler:@escaping (_ object: FPNamable) -> Void) -> FPSelectNamableViewController {
        let vc = FPSelectNamableViewController()
        vc.navigationBarTitle = navigationBarTitle
        vc.dataSource = dataSource
        vc.objectSelectedHandler = objectSelectedHandler
        return vc
    }
    
    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor.white
        
        self.tableView = UITableView()
        self.tableView.backgroundColor = UIColor.clear
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(self.tableView)
        
        let views: [String: Any] = [
            "tableView": self.tableView
        ]
        
        // tableView
        var tableViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[tableView]|", options: [], metrics: nil, views: views)
        tableViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views)
        self.view.addConstraints(tableViewConstraints)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = self.navigationBarTitle
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        }
        let obj = self.dataSource[indexPath.row]
        cell?.textLabel?.text = obj.name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.objectSelectedHandler(
            self.dataSource[indexPath.row])
    }

}
