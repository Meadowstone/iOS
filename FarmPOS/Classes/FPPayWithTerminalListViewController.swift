//
//  FPPayWithTerminalListViewController.swift
//  Farm POS
//
//  Created by Luciano Polit on 27/1/22.
//  Copyright © 2022 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit
import StripeTerminal

class FPPayWithTerminalListViewController: UITableViewController {
    
    var options: [Reader] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    let onSelection: (Reader) -> ()
    
    init(
        options: [Reader],
        onSelection: @escaping (Reader) -> ()
    ) {
        self.options = options
        self.onSelection = onSelection
        super.init(
            nibName: nil,
            bundle: nil
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "Basic"
        )
    }
    
    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return options.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "Basic",
            for: indexPath
        )
        cell.textLabel?.text = options[indexPath.row].serialNumber
        return cell
    }
    
    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        onSelection(
            options[indexPath.row]
        )
    }
    
}
