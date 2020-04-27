//
//  FPProductsViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductsViewController: FPRotationViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, FPProductViewControllerDelegate, UIActionSheetDelegate {
    
    var ed = false
    var inventory = false
    var searchBar: UISearchBar!
    var categoryName: String?
    var sections = [Dictionary<String, AnyObject>]()
    var sectionsBackup = [Dictionary<String, AnyObject>]()
    
    @IBOutlet weak var tableView: UITableView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func productsViewControllerForCategory(_ c: String?, inventory: Bool = false) -> FPProductsViewController {
        let vc = UIStoryboard(name: "ProductsAndCart", bundle: nil).instantiateViewController(withIdentifier: "FPProductsViewController") as! FPProductsViewController
        vc.categoryName = c
        vc.inventory = inventory
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = categoryName
        if categoryName == nil {
            navigationItem.title = "Products"
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductsViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        searchBar = UISearchBar(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.size.width, height: 44.0))
        searchBar.autocorrectionType = UITextAutocorrectionType.no
        searchBar.isTranslucent = false
        searchBar.barTintColor = navigationController!.navigationBar.barTintColor
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        tableView.tableHeaderView = searchBar
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(FPProductsViewController.editPressed(_:)))
        
        if inventory {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(FPProductsViewController.optionsPressed))
        }
        
        tableView.register(UINib(nibName: "FPProductCell", bundle: nil), forCellReuseIdentifier: "FPProductCell")
        searchBar.becomeFirstResponder()
        //        resetProducts()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }
    
    func optionsPressed() {
        let actionSheet = UIActionSheet(title: "Choose option", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Create New Product", "Scan barcode", "Notifications")
        actionSheet.tag = 1
        actionSheet.show(in: self.view)
    }
    
    func resetProducts() {
        if let products = FPProduct.products() {
            var s = [Dictionary<String, AnyObject>]()
//            if categoryName != nil && categoryName! == "CSA Products" {
//                for csa in FPCustomer.activeCustomer()!.csas {
//                    var p = products.filter({
//                        for aCsa in $0.csas {
//                            if aCsa.id == csa.id {
//                                return true
//                            }
//                        }
//                        return false
//                    })
//                    if p.count > 0 {
//                        s.append(["section": csa, "items": sortProducts(p)])
//                    }
//                }
//            } else {
            
//                if let ac = FPCustomer.activeCustomer() {
//                    for csa in ac.csas {
//                        var p = products.filter({
//                            [weak self] in
//                            for aCsa in $0.csas {
//                                var shouldReturn = false
//                                if self!.categoryName != nil {
//                                    shouldReturn = $0.category.name == self!.categoryName && aCsa.id == csa.id
//                                } else if aCsa.id == csa.id {
//                                    shouldReturn = true
//                                }
//                                return shouldReturn
//                            }
//                            return false
//                            })
//                        if p.count > 0 {
//                            s.append(["section": csa, "items": sortProducts(p)])
//                        }
//                        
//                    }
//                }
                
                let p = products.filter({[weak self] in
                    var shouldReturn = true //$0.csas.count == 0;
                    if self!.categoryName != nil {
                        shouldReturn = shouldReturn && $0.category.name == self!.categoryName!
                    }
                    return shouldReturn
                    })
                if p.count > 0 {
                    s.append(["section": "" as AnyObject, "items": sortProducts(p) as AnyObject])
                }
//            }
            sections = s
        }
        tableView.reloadData()
    }
    
    func editPressed(_ sender: UIBarButtonItem) {
        ed = !ed
        sender.title = ed ? "Done" : "Edit"
    }
    
    func sortProducts(_ products: [FPProduct]) -> [FPProduct] {
        let sortDescriptors = [NSSortDescriptor(key: "onSaleNow", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
        let p = (products as NSArray).sortedArray(using: sortDescriptors) as! [FPProduct]
        return p
    }
    
    func inventoryProductSelected(_ product: FPProduct, fromBarcode: Bool = false) {
//        let vc = FPInventoryProductViewController.inventoryProductViewControllerForProduct(product)
        let vc = FPCreateProductViewController.createProductViewControllerForEditProduct(product, withCompletion: { (product2) -> Void in
            if let p2 = product2 {
                product.mergeWithProduct(p2)
            }
            self.tableView.reloadData()
        })
        if fromBarcode {
            _ = self.navigationController?.popViewController(animated: false)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: UITableView data source
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let height: CGFloat = 0.0
        if (sections.count > 1 || sections[0]["section"] is FPCSA) {
            
            let label = UILabel(frame: CGRect(x: 15.0, y: 0.0, width: tableView.frame.size.width - 30.0, height: 44.0))
            label.backgroundColor = UIColor.clear
            label.textColor = UIColor.darkGray
            label.numberOfLines = 0
            label.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
            label.adjustsFontSizeToFitWidth = true
            
            if let csa = sections[section]["section"] as? FPCSA {
                label.text = "\(csa.name)"
                if csa.type == "2" {
                    label.text! +=  " - \(FPCartView.sharedCart().creditsAvailableForCSA(csa)) credits left"
                }
            } else if let text = sections[section]["section"] as? NSString {
                label.text = text as String
            }
            return max(label.sizeThatFits(CGSize(width: label.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height, 44.0)
        }
        return height
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.frame.size.width, height: 44.0))
        headerView.backgroundColor = UIColor.clear
        
        let label = UILabel(frame: CGRect(x: 15.0, y: 0.0, width: headerView.bounds.size.width - 30.0, height: headerView.bounds.size.height))
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.darkGray
        label.numberOfLines = 0
        label.font = UIFont(name: "HelveticaNeue-Light", size: 25.0)
        label.adjustsFontSizeToFitWidth = true
        
        if let csa = sections[section]["section"] as? FPCSA {
            label.text = "\(csa.name)"
            if csa.type == "2" {
                label.text! +=  " - \(FPCartView.sharedCart().creditsAvailableForCSA(csa)) credits left"
            }
        } else if let text = sections[section]["section"] as? NSString {
            label.text = text as String
        }
        label.frame.size.height = max(label.sizeThatFits(CGSize(width: label.bounds.size.width, height: CGFloat.greatestFiniteMagnitude)).height, 44.0)
        headerView.frame = CGRect(x: 0.0, y: 0.0, width: headerView.bounds.size.width, height: label.bounds.size.height)
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let p = (sections[indexPath.section]["items"] as! NSArray)[indexPath.row] as! FPProduct
        return FPProductCell.cellHeightForProduct(p, inventory: self.inventory, inTableView: tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (sections[section]["items"] as! NSArray).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPProductCell") as! FPProductCell
        cell.frame.size.width = tableView.bounds.size.width
        cell.inventory = self.inventory
        cell.product = (sections[indexPath.section]["items"] as! NSArray)[indexPath.row] as! FPProduct
        return cell
    }
    
    //MARK: UITableView delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let product = (sections[indexPath.section]["items"] as! NSArray)[indexPath.row] as! FPProduct
        
        if inventory {
            self.inventoryProductSelected(product)
        } else {
            
            if ed {
                self.inventoryProductSelected(product)
//                let vc = FPProductCreateViewController.productCreateViewControllerWithCompletion({
//                    [weak self] product in
//                    self!.resetProducts()
//                    self!.dismissViewControllerAnimated(true, completion: nil)
//                    }, product: product)
//                let nc = UINavigationController(rootViewController: vc)
//                presentViewController(nc, animated: true, completion: nil)
            } else {
                if product.onSaleNow {
                    var cartProduct = FPCartView.sharedCart().cartProductWithProduct(product)
                    var updating = true
                    if cartProduct == nil {
                        updating = false
                        cartProduct = FPCartProduct(product: product)
                    }
                    var processingCSAId: Int?
                    if let csa = sections[indexPath.section]["section"] as? FPCSA {
                        processingCSAId = csa.id
                    }
                    let vc = FPProductViewController.productNavigationViewControllerForCartProduct(cartProduct!, processingCSAId: processingCSAId, delegate: self, updating: updating)
                    present(vc, animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: UISearchBar delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if (searchText as NSString).length == 0 {
            //            sections = sectionsBackup
            sections = [Dictionary<String, AnyObject>]()
        } else {
            //            if sectionsBackup.count == 0 {
            //                sectionsBackup = sections
            //            }
            
            sections = [Dictionary<String, AnyObject>]()
            
            var s = [Dictionary<String, AnyObject>]()
            
            let products = FPProduct.products()!
            
//            if let ac = FPCustomer.activeCustomer() {
//                for csa in ac.csas {
//                    var p = products.filter({
//                        for aCsa in $0.csas {
//                            if aCsa.id == csa.id {
//                                return true
//                            }
//                        }
//                        return false
//                    })
//                    if p.count > 0 {
//                        s.append(["section": csa, "items": sortProducts(p)])
//                    }
//                    
//                }
//            }
            
            let p = products //.filter({ return $0.csas.count == 0 })
            if p.count > 0 {
                s.append(["section": "" as AnyObject, "items": sortProducts(p) as AnyObject])
            }
            for sectionInfo in s {
                var sInfo = sectionInfo
                var ps = sInfo["items"] as! [AnyObject]
                let predicate = NSPredicate(format: "name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@", searchText, " \(searchText)", searchText)
//                if inventory {
//                    predicate = NSPredicate(format: "(name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@) && trackInventory == %@", searchText, " \(searchText)", searchText, NSNumber(bool: true))
//                }
                ps = ps.filter({ (obj) -> Bool in
                    return predicate.evaluate(with: obj)
                })
                //                ps = ps.filteredArrayUsingPredicate(NSPredicate(format: "name BEGINSWITH[cd] %@ || name CONTAINS[cd] %@ || searchId BEGINSWITH[cd] %@", searchText, " \(searchText)", searchText)!)
                sInfo["items"] = ps as AnyObject?
                if ps.count > 0 {
                    sections.append(sInfo)
                }
            }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: ProductViewController delegate
    func productViewControllerDidAdd(_ pvc: FPProductViewController, cartProduct: FPCartProduct) {
        FPCartView.sharedCart().addCartProduct(cartProduct, updating: pvc.updating)
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
        navigationController!.popToRootViewController(animated: false)
    }
    
    func productViewControllerDidRemove(_ pvc: FPProductViewController, cartProduct: FPCartProduct) {
        FPCartView.sharedCart().deleteCartProduct(cartProduct)
        tableView.reloadData()
        dismiss(animated: true, completion: nil)
        navigationController!.popToRootViewController(animated: false)
    }
    
    func productViewControllerDidCancel(_ pvc: FPProductViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let title = actionSheet.buttonTitle(at: buttonIndex)?.lowercased()
        if title == "scan barcode" {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
            let vc = FPScanQRCodeViewController.scanQRCodeViewControllerForQRCodes(false, completion: { (barcodeValue) -> Void in
                let predicate = NSPredicate(format: "barcodeValue MATCHES %@", barcodeValue)
                let products = FPProduct.products()?.filter({ (obj) -> Bool in
                    return predicate.evaluate(with: obj)
                })
                if let p = products, p.count > 0 {
                    self.inventoryProductSelected(p[0], fromBarcode: true)
                } else {
                    FPAlertManager.showMessage("Product not found", withTitle: "Error")
                    _ = self.navigationController?.popViewController(animated: true)
                }
            })
            self.navigationController?.pushViewController(vc, animated: true)
        } else if title == "notifications" {
            let vc = FPTriggerAlertsViewController.triggerAlertsViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        } else if title == "create new product" {
            self.view.endEditing(true)
            
            let vc = FPCreateProductViewController.createProductViewControllerForEditProduct(nil, withCompletion: { (product) -> Void in
                if let p = product {
                    FPAlertManager.showMessage("\(p.name) - successfully created!", withTitle: "Success!")
                    self.sections = [Dictionary<String, AnyObject>]()
                    self.searchBar.text = ""
                    self.tableView.reloadData()
                }
                _ = self.navigationController?.popViewController(animated: true)
            })
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    // MARK: Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        tableView.contentInset = insets
        tableView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillChangeFrame(_ note: Notification) {
        if let kbRect = (note.userInfo![UIKeyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            let insets = UIEdgeInsetsMake(0, 0, kbRect.size.height, 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
}
