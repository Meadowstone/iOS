
//
//  FPChoiceOverlayView.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPChoiceOverlayView: UIView, UITableViewDelegate, UITableViewDataSource {

    var tableView: UITableView!
    var dataSource: Array<String>!
    var completion: ((String) -> Void)!
    var font: UIFont?
    
    
    class func choiceOverlayViewWithFrame(_ frame: CGRect, dataSource: Array<String>, font: UIFont?, completion: @escaping (String) -> Void) -> FPChoiceOverlayView {
        
        let overlay = FPChoiceOverlayView(frame: frame)
        overlay.backgroundColor = UIColor.white
        overlay.isUserInteractionEnabled = true
        overlay.layer.cornerRadius = 5.0;
        overlay.layer.borderWidth = 1.0;
        overlay.layer.borderColor = FPColorGreen.cgColor;
        if let f = font {
            overlay.font = f
        } else {
            overlay.font = UIFont(name: "HelveticaNeue", size: 20)
        }
        overlay.completion = completion
        overlay.dataSource = dataSource
        
        let tableView = UITableView(frame: overlay.bounds)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.delegate = overlay
        tableView.dataSource = overlay
        overlay.tableView = tableView
        overlay.addSubview(tableView)
        
        return overlay
    }
    
    func showInView(_ view: UIView) {
        view.addSubview(self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 57.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "choiceOverlayCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell!.textLabel!.textColor = FPColorDarkGray
            cell!.textLabel!.textAlignment = .center
            cell!.textLabel!.font = font!
            cell!.textLabel!.adjustsFontSizeToFitWidth = true
            cell!.textLabel!.minimumScaleFactor = 0.7
        }
        cell!.textLabel!.text = dataSource[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        completion(dataSource[indexPath.row])
    }
    
}
