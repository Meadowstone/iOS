//
//  FPInventoryProductViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 23/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD
import SDWebImage

class FPInventoryProductViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIActionSheetDelegate, UIAlertViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var productNameTextField: UITextField!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var boughtTextField: UITextField!
    @IBOutlet weak var remainingTextField: UITextField!
    @IBOutlet weak var soldTextField: UITextField!
    @IBOutlet weak var triggerAmountTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var barcodeTextField: UITextField!
    
    var product: FPProduct!
    var notes = [FPInventoryProductNote]()
    
    class func inventoryProductViewControllerForProduct(_ product: FPProduct) -> FPInventoryProductViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FPInventoryProductViewController") as! FPInventoryProductViewController
        vc.product = product
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Inventory product"
        
        self.tableView.estimatedRowHeight = 44.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "add_btn"), style: .plain, target: self, action: #selector(FPInventoryProductViewController.addPressed))
        
        for textField in [productNameTextField, priceTextField, triggerAmountTextField, boughtTextField, categoryTextField, soldTextField, remainingTextField, barcodeTextField] {
            let leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 20.0, height: (textField?.bounds.size.height)!))
            leftView.backgroundColor = UIColor.clear
            textField?.leftView = leftView
            textField?.leftViewMode = .always
            
            if textField === priceTextField {
                let usdLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 40.0, height: (textField?.bounds.size.height)!))
                usdLabel.font = UIFont(name: "HelveticaNeue", size: 17.0)
                usdLabel.text = "USD"
                usdLabel.textColor = FPColorRed
                textField?.rightView = usdLabel
                textField?.rightViewMode = .always
            }
        }
        
        self.productNameTextField.text = product.name
        
        self.priceTextField.text = FPCurrencyFormatter.printableCurrency(product.price)
        
        self.categoryTextField.text = product.category.name
        
        if let t = product.triggerAmount {
            self.triggerAmountTextField.text = FPCurrencyFormatter.printableCurrency(t)
        }
        
        if let b = product.barcodeValue {
            self.barcodeTextField.text = b
        }
        
        imgBtn.layer.borderColor = FPColorGreen.cgColor
        imgBtn.layer.borderWidth = 1.0
        if let url = product.imageURL {
            imgBtn.sd_setBackgroundImage(with: url, for: .normal)
        }
        
        FPServer.sharedInstance.inventoryProductNotesForProduct(product, completion: {[weak self] (errMsg, notes) -> Void in
            if let e = errMsg {
                FPAlertManager.showMessage(e, withTitle: "Error")
            } else if let n = notes {
                self?.notes += n
                self?.tableView.reloadData()
            }
        })
        
        self.updateTextFields()
        
    }
    
    func updateTextFields() {
        if let b = product.bought {
            self.boughtTextField.text = FPCurrencyFormatter.printableCurrency(b)
        } else {
            self.boughtTextField.text = FPCurrencyFormatter.printableCurrency(0.00)
        }
        
        if let r = product.remaining {
            self.remainingTextField.text = FPCurrencyFormatter.printableCurrency(r)
        } else {
            self.remainingTextField.text = FPCurrencyFormatter.printableCurrency(0.00)
        }
        
        if let s = product.sold {
            self.soldTextField.text = FPCurrencyFormatter.printableCurrency(s)
        } else {
            self.soldTextField.text = FPCurrencyFormatter.printableCurrency(0.00)
        }
    }
    
    func addPressed() {
        let actionSheet = UIActionSheet(title: "Choose option", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Add Notes", "Product Delivery", "Update Inventory", "Product Spoilage")
        actionSheet.show(in: self.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === barcodeTextField {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
            let vc = FPScanQRCodeViewController.scanQRCodeViewControllerForQRCodes(false, completion: { (barcode) -> Void in
                
                let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Processing"
                let completion = {
                    [weak self] (errMsg: String?, product: FPProduct?) -> Void in
                    hud?.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    } else {
                        _ = self?.navigationController?.popViewController(animated: true)
                        self?.product.barcodeValue = barcode
                        self?.barcodeTextField.text = product?.barcodeValue
                    }
                }
                
                FPServer.sharedInstance.productCreateWithName(self.product.name, editProduct: self.product, searchId: self.product.searchId!, price: self.priceTextField.text!, measurement: self.product.measurement, image: nil, productCategory: self.product.category, availabilityDate: self.product.availableFrom != nil ? self.product.availableFrom! : Date(), onSaleNow: self.product.onSaleNow, hidden: self.product.hidden, trackInventory: self.product.trackInventory, supplier: self.product.supplier, triggerAmount: self.product.triggerAmount, barcodeValue: barcode, completion: completion)
            })
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        }
        return true
    }
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        let cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = notes[indexPath.row].text
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
            hud?.labelText = "Processing"
            FPServer.sharedInstance.productInventoryNoteDelete(notes[indexPath.row], completion: { (errMsg) -> Void in
                hud?.hide(false)
                if let e = errMsg {
                    FPAlertManager.showMessage(e, withTitle: "Error")
                } else {
                    self.notes.remove(at: indexPath.row)
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    // MARK: - UIActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let buttonTitle = actionSheet.buttonTitle(at: buttonIndex)?.lowercased()
        
        if buttonTitle == "cancel" {
            return
        }
        
        if buttonTitle == "add notes" {
            let vc = FPAddNotesViewController.addNotesViewControllerWithCompletion({ (text) -> Void in
                let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Processing"
                FPServer.sharedInstance.productInventoryNoteCreateForProduct(self.product, text: text, completion: { (errMsg, note) -> Void in
                    hud?.hide(false)
                    if let e = errMsg {
                        FPAlertManager.showMessage(e, withTitle: "Error")
                    } else if let n = note {
                        _ = self.navigationController?.popViewController(animated: true)
                        self.notes.insert(n, at: 0)
                        self.tableView.reloadData()
                    }
                })
            })
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        var type: Int = 0
        var title = ""
        var defaultValue = ""
        
        if buttonTitle == "product spoilage" {
            type = 2
            title = "Product Spoilage"
        } else if buttonTitle == "product delivery" {
            type = 3
            title = "Product Delivery"
        } else if buttonTitle == "update inventory" {
            type = 1
            title = "Update Inventory"
            if let r = product.remaining {
                defaultValue = "\(r)"
            }
        }
        
        let alert = UIAlertView(title: title, message: "", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Submit")
        alert.tag = type
        alert.alertViewStyle = .plainTextInput
        alert.textField(at: 0)?.text = defaultValue
        alert.textField(at: 0)?.keyboardType = .decimalPad
        alert.show()
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.buttonTitle(at: buttonIndex)?.lowercased() == "submit" {
            let text = alertView.textField(at: 0)!.text
            
            if let amount = NumberFormatter().number(from: text!)?.doubleValue, amount > 0 {
                let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Processing"
                FPServer.sharedInstance.productInventoryAddForProduct(product, amount: amount, type: alertView.tag) { (errMsg, product) -> Void in
                    hud?.hide(false)
                    if let e = errMsg {
                        FPAlertManager.showMessage(e, withTitle: "Error")
                    } else {
                        self.product.remaining = product?.remaining
                        self.product.sold = product?.sold
                        self.product.bought = product?.bought
                        self.updateTextFields()
                    }
                }
            } else {
                FPAlertManager.showMessage("Enter a valid amount", withTitle: "Error")
            }
        }
    }
    
    
}
