//
//  FPCashCheckSummaryViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 23/06/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCashCheckSummaryViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAlertViewDelegate {
    
    enum FPCashCheckSummaryViewControllerAction {
        case close
        case segmentedChange
    }
    
    var action: FPCashCheckSummaryViewControllerAction?
    var days = [NSDictionary]()
    var hasChanges = false
    var closeBlock: (() -> Void)!
    
    @IBOutlet weak var cashSegmented: UISegmentedControl!
    @IBOutlet weak var saveBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func textFieldDidEndEditing(_ sender: UITextField) {
        if let cell = tableViewCellForTextField(sender) {
            if let indexPath = tableView.indexPath(for: cell) {
                let nf = NumberFormatter()
                nf.locale = Locale(identifier: "en_US")
                nf.numberStyle = .decimal
                nf.maximumFractionDigits = 2
                if let actual = nf.number(from: sender.text!) as? Double {
                    let day = days[indexPath.row].mutableCopy() as! NSMutableDictionary
                    day["actual"] = actual
                    days[indexPath.row] = day
                    hasChanges = true
                }
            }
        }
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        if (sender.text! as NSString).length > 0 {
            let text = (sender.text! as NSString).substring(from: (sender.text! as NSString).length - 1)
            sender.text = (sender.text! as NSString).substring(to: (sender.text! as NSString).length - 1)
            let t = FPInputValidator.preprocessCurrencyText(text, relativeTo: sender.text!)
            if FPInputValidator.shouldAddString(t, toString: sender.text!, maxInputCount: Int.max, isDecimal: true) {
                sender.text = sender.text! + t
            }
        }
    }
    
    func tableViewCellForTextField(_ textField: UITextField) -> UITableViewCell? {
        var view = textField.superview
        var cell: UITableViewCell?
        while view != nil {
            if let v = view as? UITableViewCell {
                cell = v
                break
            }
            view = view?.superview
        }
        return cell
    }
    
    @IBAction func savePressed(_ sender: AnyObject) {
        self.view.endEditing(true)
        
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Processing..."
        FPServer.sharedInstance.cashCheckSummarySetForCash(cashSegmented.selectedSegmentIndex == 0, withDays: self.days) { (errors) -> Void in
            hud?.hide(false)
            if let e = errors {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else {
                self.hasChanges = false
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func segmentedValueChanged(_ sender: AnyObject) {
        self.view.endEditing(true)
        if hasChanges {
            self.cashSegmented.selectedSegmentIndex = self.cashSegmented.selectedSegmentIndex == 0 ? 1 : 0
            displayAlertForAction(.segmentedChange)
        } else {
            self.reloadDays()
        }
    }
    
    class func cashCheckSummaryNavigationViewControllerWithCloseBlock(_ closeBlock:@escaping () -> Void) -> UINavigationController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPCashCheckSummaryViewController") as! FPCashCheckSummaryViewController
        vc.closeBlock = closeBlock
        let nc = UINavigationController(rootViewController: vc)
        return nc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Cash / Check Summary"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(FPCashCheckSummaryViewController.closePressed))
        preferredContentSize = CGSize(width: 640, height: 488)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.reloadDays()
    }
    
    func reloadDays() {
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Loading..."
        FPServer.sharedInstance.cashCheckSummaryForCash(cashSegmented.selectedSegmentIndex == 0, withCompletion: { (errors, days) -> Void in
            hud?.hide(false)
            if let e = errors {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else if let d = days {
                self.days = d
                self.tableView.reloadData()
            }
        })
    }
    
    @objc func closePressed() {
        self.view.endEditing(true)
        if hasChanges {
            displayAlertForAction(.close)
        } else {
            closeBlock()
        }
    }
    
    func displayAlertForAction(_ action: FPCashCheckSummaryViewControllerAction) {
        self.action = action
        UIAlertView(title: "Warning", message: "You have pending changes.", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Save changes", "Discard changes").show()
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return days.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = nil
        
        let day = self.days[indexPath.row]
        let dateLabel = cell.viewWithTag(1) as! UILabel
        
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        df.locale = Locale(identifier: "en_US")
        if let date = df.date(from: day["day"] as! String) {
            var dayComponent = DateComponents()
            dayComponent.day = 1
            let theCalendar = Calendar.current
            let filterComponents = theCalendar.dateComponents([.day, .month, .year], from: Date(), to: date)
            
            var title = ""
            if (filterComponents.year == 0 && filterComponents.month == 0 && filterComponents.day == 0) {
                title = "Today";
            }
            else if (filterComponents.year == 0 && filterComponents.month == 0 && filterComponents.day == -1) {
                title = "Yesterday";
            }
            else {
                df.dateFormat = "EEEE MM/dd/yyyy"
                title = df.string(from: date)
            }
            dateLabel.text = title
        }
        
        let recordedLabel = cell.viewWithTag(2) as! UILabel
        recordedLabel.text = "$" + FPCurrencyFormatter.printableCurrency(day["recorded"] as! Double)
        
        let actualTextField = cell.viewWithTag(3) as! UITextField
        actualTextField.text = FPCurrencyFormatter.printableCurrency(day["actual"] as! Double)
        
        return cell
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (string as NSString).length == 0 {
            return true
        }
        
        let cs = CharacterSet(charactersIn: "0123456789.")
        if (string as NSString).rangeOfCharacter(from: cs).length == 0 {
            return false
        }
        
        return true
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(_ alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 1 { // Save changes
            self.savePressed(self.saveBtn)
        } else if buttonIndex == 2 { // Discard changes and proceed based on action
            self.hasChanges = false
            if self.action == .segmentedChange {
                self.cashSegmented.selectedSegmentIndex = self.cashSegmented.selectedSegmentIndex == 0 ? 1 : 0
                self.segmentedValueChanged(self.cashSegmented)
            } else {
                self.closePressed()
            }
        }
    }
    
}
