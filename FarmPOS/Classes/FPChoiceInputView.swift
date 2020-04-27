//
//  FPChoiceInputView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 6/30/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPChoiceInputView: UIView, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var dataSource: Array<String>!
    var completion: ((String) -> Void)!
    var cellLabelFontSize: CGFloat!
    
    class func choiceInputViewWithDataSource(_ dataSource: [String], completion: @escaping (_ choice: String) -> Void) -> FPChoiceInputView {
        
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        var rect = UIScreen.main.bounds
        rect.size.height = UIScreen.main.bounds.size.height / 3
        let choiceView = FPChoiceInputView(frame: rect)
        choiceView.completion = completion
        choiceView.dataSource = dataSource
        choiceView.cellLabelFontSize = isIPad ? 25 : 18
        
        let toolbar = UIView(frame: CGRect(x: 0, y: 0, width: choiceView.bounds.size.width, height: isIPad ? 44 : 38))
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.backgroundColor = UINavigationBar.appearance().barTintColor
        toolbar.isUserInteractionEnabled = true
        choiceView.addSubview(toolbar)
        
        let view = FPAppDelegate.instance().window?.rootViewController!.view
        let doneBtn = UIButton(type: .custom)
        doneBtn.autoresizingMask = .flexibleLeftMargin
        doneBtn.frame = CGRect(x: toolbar.bounds.size.width - 60, y: 0, width: 60, height: toolbar.bounds.size.height)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel!.font = UIFont(name: "HelveticaNeue", size: 20)
        doneBtn.addTarget(view, action: #selector(endEditing(_:)), for: .touchUpInside)
        toolbar.addSubview(doneBtn)
        
        rect.size.height -= toolbar.bounds.size.height
        rect.origin.y += toolbar.bounds.size.height
        let tableView = UITableView(frame: rect)
        tableView.rowHeight = isIPad ? 50 : 44
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = choiceView
        tableView.dataSource = choiceView
        choiceView.addSubview(tableView)
        
        return choiceView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
            cell!.textLabel!.textAlignment = .center
            cell!.textLabel!.font = UIFont(name: "HelveticaNeue", size: cellLabelFontSize)
        }
        cell!.textLabel!.text = dataSource[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completion(dataSource[indexPath.row])
    }
    
}
