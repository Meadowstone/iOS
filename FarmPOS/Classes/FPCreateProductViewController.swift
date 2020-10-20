//
//  FPCreateProductViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 27/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD
import SDWebImage

class FPCreateProductViewController: FPRotationViewController, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate {
    
    var editProduct: FPProduct?
    var completion: ((_ product: FPProduct?) -> Void)?
    var selectedImage: UIImage?
    var measurements = FPMeasurement.allMeasurements()!
    var selectedMeasurement: FPMeasurement! {
        didSet {
            self.measurementTextField.text = selectedMeasurement.name
        }
    }
    var selectedCategory: FPProductCategory? {
        didSet {
            self.categoryTextField.text = selectedCategory?.name
        }
    }
    var selectedSupplier: FPProductSupplier? {
        didSet {
            self.supplierTextField.text = selectedSupplier?.name
        }
    }
    
    var productTableView: UITableView!
    var productTableHeaderView: UIView!
    var productTableHeaderViewSaveBtn: UIButton!
    
    var inventoryTableView: UITableView!
    var inventoryTableHeaderView: UIView!
    var inventoryTableHeaderViewHistoryBtn: UIButton!
    var inventoryTableHeaderViewSaveBtn: UIButton!
    
    // Expandables
    var inventoryExpandableView: UIView!
    var inventoryExpandableViewOverlayView: UIView?
    var inventoryExpandableViewOverlayViewLabel: UILabel?
    
    // Headers
    var headerLabels = [UILabel]()
    var nameHeaderLabel: UILabel!
    var searchIDHeaderLabel: UILabel!
    var imageHeaderLabel: UILabel!
    var measurementHeaderLabel: UILabel!
    var priceHeaderLabel: UILabel!
    var categoryHeaderLabel: UILabel!
    var visibilityHeaderLabel: UILabel!
    var inventoryHeaderLabel: UILabel!
    var supplierHeaderLabel: UILabel!
    var triggerAmountHeaderLabel: UILabel!
    var barcodeHeaderLabel: UILabel!
    var boughtHeaderLabel: UILabel!
    var remainingHeaderLabel: UILabel!
    var soldHeaderLabel: UILabel!
    
    // Controls and inputs
    var textFields = [UITextField]()
    var nameTextField: UITextField!
    var searchIDTextField: UITextField!
    var imageBtn: UIButton!
    var measurementTextField: UITextField!
    var priceTextField: UITextField!
    var categoryTextField: UITextField!
    var visibilitySegmented: UISegmentedControl!
    var inventorySegmented: UISegmentedControl!
    var supplierTextField: UITextField!
    var triggerAmountTextField: UITextField!
    var titleSegmented: UISegmentedControl?
    var barcodeTextField: UITextField!
    var boughtTextField: UITextField!
    var remainingTextField: UITextField!
    var soldTextField: UITextField!
    
    // Layout constants
    let headerLabelXPadding = 20.0
    let yPadding = 8.0
    let textFieldHeight = 47.0
    let headerLabelHeight = 21.0
    let segmentedHeight = 29.0
    
    
    class func createProductViewControllerForEditProduct(_ editProduct: FPProduct?, withCompletion completion: ((_ product: FPProduct?) -> Void)?) -> FPCreateProductViewController {
        let vc = FPCreateProductViewController()
        vc.editProduct = editProduct
        vc.completion = completion
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Create New Product"
        self.updateNavigationBar()
        
        if self.editProduct != nil {
            self.titleSegmented = UISegmentedControl(items: ["Product", "Inventory"])
            self.titleSegmented?.selectedSegmentIndex = 0
            self.titleSegmented?.addTarget(self, action: #selector(FPCreateProductViewController.segmentedValueChanged(_:)), for: UIControl.Event.valueChanged)
            self.navigationItem.titleView = self.titleSegmented
        }
        
        // Register observers
        NotificationCenter.default.addObserver(self, selector: #selector(FPCreateProductViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPCreateProductViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Customize controller appearance
        UIApplication.shared.statusBarStyle = .lightContent
        
        navigationController!.navigationBar.isTranslucent = false
        
        if self.selectedMeasurement == nil {
            self.selectedMeasurement = self.measurements[0]
        }
        
        self.productTableView.tableFooterView = UIView()
        self.inventoryTableView.tableFooterView = UIView()
        
    }
    
    func updateNavigationBar() {
        //        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "savePressed")
        if let t = self.titleSegmented, t.selectedSegmentIndex == 1 {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "add_btn"), style: .plain, target: self, action: #selector(FPCreateProductViewController.addPressed))
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @objc func historyPressed() {
        guard let editProduct = editProduct else { return }
        let vc = FPInventoryProductHistoryViewController.inventoryProductHistoryViewControllerForProduct(
            editProduct,
            historyUpdated: { [weak self] in
                self?.refreshHistoryRelatedViews(for: editProduct)
            }
        )
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func savePressed() {
        var errors = ""
        if (self.nameTextField.text! as NSString).length == 0 {
            errors = "\nEnter name"
        }
        if (self.searchIDTextField.text! as NSString).length == 0 {
            errors = "\nEnter search id"
        }
        //        if self.selectedImage == nil && self.editProduct == nil {
        //            errors = "\nSelect picture"
        //        }
        if self.selectedCategory == nil {
            errors = "\nSelect product category"
        }
        
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        let n: NSNumber? = nf.number(from: self.priceTextField.text!)
        var d = 0.00
        if n != nil {
            d = n!.doubleValue
        }
        if d == 0.00 {
            errors = "\nEnter price"
        }
        
        if (errors as NSString).length != 0 {
            FPAlertManager.showMessage(errors, withTitle: "Error")
            return
        }
        
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Processing"
        let completion = {
            [weak self] (errMsg: String?, product: FPProduct?) -> Void in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self!.completion?(product)
            }
        }
        
        var triggerAmount: Double?
        if self.triggerAmountTextField.text!.count > 0 {
            triggerAmount = NumberFormatter().number(from: self.triggerAmountTextField.text!)?.doubleValue
        }
        
        let trackInventory = self.inventorySegmented.selectedSegmentIndex == 0
        if !trackInventory {
            triggerAmount = nil
            selectedSupplier = nil
        }
        
        var onSaleNow = true
        if let e = self.editProduct {
            onSaleNow = e.onSaleNow
        }
        
        FPServer.sharedInstance.productCreateWithName(self.nameTextField.text!, editProduct: self.editProduct, searchId: self.searchIDTextField.text!, price: self.priceTextField.text!, measurement: self.selectedMeasurement, image: self.selectedImage, productCategory: self.selectedCategory!, availabilityDate: nil, onSaleNow: onSaleNow, hidden: self.visibilitySegmented.selectedSegmentIndex == 1, trackInventory: trackInventory, supplier: self.selectedSupplier, triggerAmount: triggerAmount, barcodeValue: self.editProduct?.barcodeValue, completion: completion)
    }
    
    @objc func addPressed() {
        let actionSheet = UIActionSheet(title: "Choose option", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Product Delivery", "Update Inventory", "Product Spoilage")
        actionSheet.tag = 2
        actionSheet.show(in: self.view)
    }
    
    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = UIColor(red: 245 / 255, green: 245 / 255, blue: 245 / 255, alpha: 1)
        
        self.instantiateBasicViewHierarchy()
        self.populateSubviews()
        self.applyConstraints()
    }
    
    func assembleTableHeaderViewForProduct() {
        
        var views = [String: Any]()
        views["tableView"] = self.productTableView
        views["productTableHeaderView"] = self.productTableHeaderView
        
        self.productTableView.tableHeaderView = self.productTableHeaderView
        
        // productTableHeaderView
        let productTableHeaderViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[productTableHeaderView(==tableView)]", options: [], metrics: nil, views: views)
        self.view.addConstraints(productTableHeaderViewConstraints)
        
        // productTableHeaderViewSaveBtn
        self.addConstraintsToView(self.view, forView: self.productTableHeaderViewSaveBtn, placeBelowView: nil, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: 40.0)
        
        // nameHeaderLabel
        self.addConstraintsToView(self.view, forView: self.nameHeaderLabel, placeBelowView: self.productTableHeaderViewSaveBtn, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // nameTextField
        self.addConstraintsToView(self.view, forView: self.nameTextField, placeBelowView: self.nameHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // searchIDHeaderLabel
        self.addConstraintsToView(self.view, forView: self.searchIDHeaderLabel, placeBelowView: self.nameTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // searchIDTextField
        self.addConstraintsToView(self.view, forView: self.searchIDTextField, placeBelowView: self.searchIDHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // visibilityHeaderLabel
        self.addConstraintsToView(self.view, forView: self.visibilityHeaderLabel, placeBelowView: self.searchIDTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // visibilitySegmented
        self.addConstraintsToView(self.view, forView: self.visibilitySegmented, placeBelowView: self.visibilityHeaderLabel, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: segmentedHeight)
        
        // imageHeaderLabel
        self.addConstraintsToView(self.view, forView: self.imageHeaderLabel, placeBelowView: self.visibilitySegmented, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // imageBtn
        self.addConstraintsToView(self.view, forView: self.imageBtn, placeBelowView: self.imageHeaderLabel, xPadding: -1, yPadding: yPadding, width: 280, height: 280)
        self.view.addConstraint(NSLayoutConstraint(item: self.imageBtn!, attribute: .centerX, relatedBy: .equal, toItem: self.imageBtn.superview, attribute: .centerX, multiplier: 1, constant: 0))
        
        // measurementHeaderLabel
        self.addConstraintsToView(self.view, forView: self.measurementHeaderLabel, placeBelowView: self.imageBtn, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // measurementTextField
        self.addConstraintsToView(self.view, forView: self.measurementTextField, placeBelowView: self.measurementHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // priceHeaderLabel
        self.addConstraintsToView(self.view, forView: self.priceHeaderLabel, placeBelowView: self.measurementTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // priceTextField
        self.addConstraintsToView(self.view, forView: self.priceTextField, placeBelowView: self.priceHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // categoryHeaderLabel
        self.addConstraintsToView(self.view, forView: self.categoryHeaderLabel, placeBelowView: self.priceTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // categoryTextField
        self.addConstraintsToView(self.view, forView: self.categoryTextField, placeBelowView: self.categoryHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight, determinesHeaderHeight: editProduct != nil)
        
        if editProduct == nil {
            
            // inventoryHeaderLabel
            self.addConstraintsToView(self.view, forView: self.inventoryHeaderLabel, placeBelowView: self.categoryTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
            
            // inventorySegmented
            self.addConstraintsToView(self.view, forView: self.inventorySegmented, placeBelowView: self.inventoryHeaderLabel, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: segmentedHeight, determinesHeaderHeight: editProduct != nil)
            
            /**
            *  inventoryExpandableView contents
            **/
            
            // triggerAmountHeaderLabel
            self.addConstraintsToView(self.productTableHeaderView, forView: self.triggerAmountHeaderLabel, placeBelowView: nil, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
            
            // triggerAmountTextField
            self.addConstraintsToView(self.productTableHeaderView, forView: self.triggerAmountTextField, placeBelowView: self.triggerAmountHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
            
            // supplierHeaderLabel
            self.addConstraintsToView(self.productTableHeaderView, forView: self.supplierHeaderLabel, placeBelowView: self.triggerAmountTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
            
            // supplierTextField
            self.addConstraintsToView(self.productTableHeaderView, forView: self.supplierTextField, placeBelowView: self.supplierHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight, determinesHeaderHeight: true, heightMargin: 0)
            
            /************************/
            
            self.addConstraintsToView(self.view, forView: self.inventoryExpandableView, placeBelowView: self.inventorySegmented, xPadding: 0, yPadding: yPadding, width: 0, height: 0, determinesHeaderHeight: true)
        }
        
    }
    
    func assembleTableHeaderViewForInventory() {
        
        var views = [String: Any]()
        views["tableView"] = self.inventoryTableView
        views["inventoryTableHeaderView"] = self.inventoryTableHeaderView
        
        self.inventoryTableView.tableHeaderView = self.inventoryTableHeaderView
        
        // inventoryTableHeaderView
        let inventoryTableHeaderViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[inventoryTableHeaderView(==tableView)]", options: [], metrics: nil, views: views)
        self.view.addConstraints(inventoryTableHeaderViewConstraints)
        
        // inventoryTableHeaderViewHistoryBtn
        self.addConstraintsToView(self.view, forView: self.inventoryTableHeaderViewHistoryBtn, placeBelowView: nil, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: 40.0)
        
        // inventoryTableHeaderViewSaveBtn
        self.addConstraintsToView(self.view, forView: self.inventoryTableHeaderViewSaveBtn, placeBelowView: self.inventoryTableHeaderViewHistoryBtn, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: 40.0)
        
        // inventoryHeaderLabel
        self.addConstraintsToView(self.view, forView: self.inventoryHeaderLabel, placeBelowView: self.inventoryTableHeaderViewSaveBtn, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // inventorySegmented
        self.addConstraintsToView(self.view, forView: self.inventorySegmented, placeBelowView: self.inventoryHeaderLabel, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: segmentedHeight)
        
        /**
        *  inventoryExpandableView contents
        **/
        
        // triggerAmountHeaderLabel
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.triggerAmountHeaderLabel, placeBelowView: nil, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // triggerAmountTextField
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.triggerAmountTextField, placeBelowView: self.triggerAmountHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // supplierHeaderLabel
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.supplierHeaderLabel, placeBelowView: self.triggerAmountTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // supplierTextField
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.supplierTextField, placeBelowView: self.supplierHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // barcodeHeaderLabel
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.barcodeHeaderLabel, placeBelowView: self.supplierTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // barcodeTextField
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.barcodeTextField, placeBelowView: self.barcodeHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // boughtHeaderLabel
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.boughtHeaderLabel, placeBelowView: self.barcodeTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // boughtTextField
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.boughtTextField, placeBelowView: self.boughtHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // remainingHeaderLabel
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.remainingHeaderLabel, placeBelowView: self.boughtTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // remainingTextField
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.remainingTextField, placeBelowView: self.remainingHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight)
        
        // soldHeaderLabel
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.soldHeaderLabel, placeBelowView: self.remainingTextField, xPadding: headerLabelXPadding, yPadding: yPadding, width: 0, height: headerLabelHeight)
        
        // soldTextField
        self.addConstraintsToView(self.inventoryTableHeaderView, forView: self.soldTextField, placeBelowView: self.soldHeaderLabel, xPadding: 0, yPadding: yPadding, width: 0, height: textFieldHeight, determinesHeaderHeight: true, heightMargin: 0)
        
        /************************/
        
        self.addConstraintsToView(self.view, forView: self.inventoryExpandableView, placeBelowView: self.inventorySegmented, xPadding: 0, yPadding: yPadding, width: 0, height: 0)
    }
    
    func genericHeaderLabel() -> UILabel {
        let headerLabelFont = UIFont(name: "HelveticaNeue-Light", size: 12)
        let textColor = UIColor(red: 71 / 255, green: 71 / 255, blue: 71 / 255, alpha: 1)
        
        let genericHeaderLabel = UILabel()
        genericHeaderLabel.backgroundColor = UIColor.clear
        genericHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        genericHeaderLabel.font = headerLabelFont
        genericHeaderLabel.textColor = textColor
        self.headerLabels.append(genericHeaderLabel)
        
        return genericHeaderLabel
    }
    
    func genericHeaderLabelAddedToHeaderView() -> UILabel {
        let genericHeaderLabel = self.genericHeaderLabel()
        self.productTableHeaderView.addSubview(genericHeaderLabel)
        return genericHeaderLabel
    }
    
    func genericTextField() -> UITextField {
        let textFieldFont = UIFont(name: "HelveticaNeue-Light", size: 16)
        let textFieldBackgroundImage = UIImage(named: "activity_input_bg")
        let textColor = UIColor(red: 71 / 255, green: 71 / 255, blue: 71 / 255, alpha: 1)
        
        let genericTextField = UITextField()
        genericTextField.translatesAutoresizingMaskIntoConstraints = false
        genericTextField.background = textFieldBackgroundImage
        genericTextField.font = textFieldFont
        genericTextField.textColor = textColor
        self.textFields.append(genericTextField)
        
        return genericTextField
    }
    
    func genericTextFieldAddedToHeaderView() -> UITextField {
        let genericTextField = self.genericTextField()
        self.productTableHeaderView.addSubview(genericTextField)
        return genericTextField
    }
    
    func instantiateBasicViewHierarchy() {
        
        self.inventoryTableView = UITableView()
        self.inventoryTableView.backgroundColor = UIColor.clear
        self.inventoryTableView.translatesAutoresizingMaskIntoConstraints = false
        self.inventoryTableView.isHidden = true
        self.view.addSubview(self.inventoryTableView)
        
        self.productTableView = UITableView()
        self.productTableView.backgroundColor = UIColor.clear
        self.productTableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.productTableView)
        
        self.productTableHeaderView = UIView()
        self.productTableHeaderView.isUserInteractionEnabled = true
        self.productTableHeaderView.backgroundColor = UIColor.clear
        self.productTableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        self.inventoryTableHeaderView = UIView()
        self.inventoryTableHeaderView.isUserInteractionEnabled = true
        self.inventoryTableHeaderView.backgroundColor = UIColor.clear
        self.inventoryTableHeaderView.translatesAutoresizingMaskIntoConstraints = false

        self.productTableHeaderViewSaveBtn = UIButton(type: .custom) 
        self.productTableHeaderViewSaveBtn.translatesAutoresizingMaskIntoConstraints = false
        self.productTableHeaderViewSaveBtn.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        self.productTableHeaderViewSaveBtn.setTitle("Save", for: .normal)
        self.productTableHeaderViewSaveBtn.setTitleColor(UIColor.white, for: .normal)
        self.productTableHeaderViewSaveBtn.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20)
        self.productTableHeaderViewSaveBtn.addTarget(self, action: #selector(FPCreateProductViewController.savePressed), for: .touchUpInside)
        self.productTableHeaderView.addSubview(self.productTableHeaderViewSaveBtn)
        
        self.inventoryTableHeaderViewSaveBtn = UIButton(type: .custom) 
        self.inventoryTableHeaderViewSaveBtn.translatesAutoresizingMaskIntoConstraints = false
        self.inventoryTableHeaderViewSaveBtn.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        self.inventoryTableHeaderViewSaveBtn.setTitle("Save", for: .normal)
        self.inventoryTableHeaderViewSaveBtn.setTitleColor(UIColor.white, for: .normal)
        self.inventoryTableHeaderViewSaveBtn.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20)
        self.inventoryTableHeaderViewSaveBtn.addTarget(self, action: #selector(FPCreateProductViewController.savePressed), for: .touchUpInside)
        self.inventoryTableHeaderView.addSubview(self.inventoryTableHeaderViewSaveBtn)
        
        self.inventoryTableHeaderViewHistoryBtn = UIButton(type: .custom) 
        self.inventoryTableHeaderViewHistoryBtn.translatesAutoresizingMaskIntoConstraints = false
        self.inventoryTableHeaderViewHistoryBtn.setBackgroundImage(UIImage(named: "green_btn"), for: .normal)
        self.inventoryTableHeaderViewHistoryBtn.setTitle("History", for: .normal)
        self.inventoryTableHeaderViewHistoryBtn.setTitleColor(UIColor.white, for: .normal)
        self.inventoryTableHeaderViewHistoryBtn.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 20)
        self.inventoryTableHeaderViewHistoryBtn.addTarget(self, action: #selector(FPCreateProductViewController.historyPressed), for: .touchUpInside)
        self.inventoryTableHeaderView.addSubview(self.inventoryTableHeaderViewHistoryBtn)
        
        self.nameHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.nameTextField = self.genericTextFieldAddedToHeaderView()
        
        self.searchIDHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.searchIDTextField = self.genericTextFieldAddedToHeaderView()
        self.searchIDTextField.keyboardType = UIKeyboardType.numberPad
        
        self.imageHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.imageBtn = UIButton(type: .custom)
        self.imageBtn.translatesAutoresizingMaskIntoConstraints = false
        self.imageBtn.addTarget(self, action: #selector(FPCreateProductViewController.imagePressed), for: UIControl.Event.touchUpInside)
        self.imageBtn.backgroundColor = UIColor.clear
        self.imageBtn.layer.borderColor = FPColorGreen.cgColor
        self.imageBtn.layer.borderWidth = 1.0
        self.productTableHeaderView.addSubview(self.imageBtn)
        
        self.measurementHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.measurementTextField = self.genericTextFieldAddedToHeaderView()
        
        self.priceHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.priceTextField = self.genericTextFieldAddedToHeaderView()
        self.priceTextField.addTarget(self, action: #selector(FPCreateProductViewController.textFieldEditingChanged(_:)), for: UIControl.Event.editingChanged)
        self.priceTextField.keyboardType = UIKeyboardType.decimalPad
        
        self.categoryHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.categoryTextField = self.genericTextFieldAddedToHeaderView()
        
        self.visibilityHeaderLabel = self.genericHeaderLabelAddedToHeaderView()
        
        self.visibilitySegmented = UISegmentedControl(items: ["Visibile", "Hidden"])
        self.visibilitySegmented.translatesAutoresizingMaskIntoConstraints = false
        self.visibilitySegmented.addTarget(self, action: #selector(FPCreateProductViewController.segmentedValueChanged(_:)), for: UIControl.Event.valueChanged)
        self.visibilitySegmented.selectedSegmentIndex = 0
        self.visibilitySegmented.tintColor = FPColorGreen
        self.productTableHeaderView.addSubview(self.visibilitySegmented)
        
        var conditionalHeaderSubviews = [UIView]()
        
        self.inventoryHeaderLabel = self.genericHeaderLabel()
        conditionalHeaderSubviews.append(self.inventoryHeaderLabel)
        
        self.inventorySegmented = UISegmentedControl(items: ["Enabled", "Disabled"])
        self.inventorySegmented.translatesAutoresizingMaskIntoConstraints = false
        self.inventorySegmented.addTarget(self, action: #selector(FPCreateProductViewController.segmentedValueChanged(_:)), for: UIControl.Event.valueChanged)
        self.inventorySegmented.selectedSegmentIndex = 0
        self.inventorySegmented.tintColor = FPColorGreen
        conditionalHeaderSubviews.append(self.inventorySegmented)
        
        self.inventoryExpandableView = UIView()
        self.inventoryExpandableView.clipsToBounds = true
        self.inventoryExpandableView.translatesAutoresizingMaskIntoConstraints = false
        self.inventoryExpandableView.backgroundColor = UIColor.clear
        conditionalHeaderSubviews.append(self.inventoryExpandableView)
        self.triggerAmountHeaderLabel = self.genericHeaderLabel()
        self.inventoryExpandableView.addSubview(self.triggerAmountHeaderLabel)
        
        self.triggerAmountTextField = self.genericTextField()
        self.triggerAmountTextField.addTarget(self, action: #selector(FPCreateProductViewController.textFieldEditingChanged(_:)), for: UIControl.Event.editingChanged)
        self.triggerAmountTextField.keyboardType = UIKeyboardType.decimalPad
        self.inventoryExpandableView.addSubview(self.triggerAmountTextField)
        
        self.supplierHeaderLabel = self.genericHeaderLabel()
        self.inventoryExpandableView.addSubview(self.supplierHeaderLabel)
        
        self.supplierTextField = self.genericTextField()
        self.inventoryExpandableView.addSubview(self.supplierTextField)
        
        for view in conditionalHeaderSubviews {
            if editProduct == nil {
                self.productTableHeaderView.addSubview(view)
            } else {
                self.inventoryTableHeaderView.addSubview(view)
            }
        }
        
        if editProduct != nil {
            self.barcodeHeaderLabel = self.genericHeaderLabel()
            self.inventoryExpandableView.addSubview(self.barcodeHeaderLabel)
            self.boughtHeaderLabel = self.genericHeaderLabel()
            self.inventoryExpandableView.addSubview(self.boughtHeaderLabel)
            self.remainingHeaderLabel = self.genericHeaderLabel()
            self.inventoryExpandableView.addSubview(self.remainingHeaderLabel)
            self.soldHeaderLabel = self.genericHeaderLabel()
            self.inventoryExpandableView.addSubview(self.soldHeaderLabel)
            
            self.barcodeTextField = self.genericTextField()
            self.inventoryExpandableView.addSubview(self.barcodeTextField)
            self.boughtTextField = self.genericTextField()
            self.inventoryExpandableView.addSubview(self.boughtTextField)
            self.remainingTextField = self.genericTextField()
            self.inventoryExpandableView.addSubview(self.remainingTextField)
            self.soldTextField = self.genericTextField()
            self.inventoryExpandableView.addSubview(self.soldTextField)
        }
        
    }
    
    func populateSubviews() {
        self.nameHeaderLabel.text = "PRODUCT NAME"
        self.searchIDHeaderLabel.text = "SEARCH IDENTIFIER"
        self.imageHeaderLabel.text = "PICTURE"
        self.measurementHeaderLabel.text = "MEASUREMENT"
        self.priceHeaderLabel.text = "PRICE"
        self.categoryHeaderLabel.text = "CATEGORY"
        self.visibilityHeaderLabel.text = "PRODUCT VISIBILITY"
        self.inventoryHeaderLabel.text = "INVENTORY"
        self.triggerAmountHeaderLabel.text = "TRIGGER AMOUNT"
        self.supplierHeaderLabel.text = "SUPPLIER"
        
        self.nameTextField.placeholder = "Enter a product name"
        self.searchIDTextField.placeholder = "Enter a search ID"
        self.measurementTextField.placeholder = "Select measurement"
        self.priceTextField.placeholder = "Enter the price"
        self.categoryTextField.placeholder = "Select product category"
        self.triggerAmountTextField.placeholder = "Trigger amount (optional)"
        self.supplierTextField.placeholder = "Product supplier (optional)"
        
        if self.editProduct != nil {
            self.barcodeHeaderLabel.text = "BARCODE"
            self.boughtHeaderLabel.text = "BOUGHT"
            self.remainingHeaderLabel.text = "REMAINING"
            self.soldHeaderLabel.text = "SOLD"
            
            self.boughtTextField.placeholder = "0"
            self.remainingTextField.placeholder = "0"
            self.soldTextField.placeholder = "0"
            self.barcodeTextField.placeholder = "Set barcode (optional)"
        }
        
        self.imageBtn.setBackgroundImage(UIImage(named: "category_placeholder"), for: .normal)
        
        // Select maximum searchId among all products + 1
        var num = -1
        for product in FPProduct.products()! {
            if let s = product.searchId {
                if let n = Int(s) {
                    num = max(num, n)
                }
            }
        }
        searchIDTextField.text = "\(num + 1)"
        
        if let p = editProduct {
            self.nameTextField.text = p.name
            self.selectedCategory = p.category
            self.selectedMeasurement = p.measurement
            self.searchIDTextField.text = p.searchId
            if let url = p.imageURL, url.absoluteString.count > 0 {
                self.imageBtn.sd_setBackgroundImage(with: url, for: .normal)
            } else {
                self.imageBtn.setBackgroundImage(UIImage(named: "category_placeholder"), for: .normal)
            }
            self.priceTextField.text = FPCurrencyFormatter.printableCurrency(p.price)
            self.visibilitySegmented.selectedSegmentIndex = p.hidden ? 1 : 0
            self.inventorySegmented.selectedSegmentIndex = p.trackInventory ? 0 : 1
            self.processInventoryOverlay(p.trackInventory)
            if let triggerAmount = p.triggerAmount {
                self.triggerAmountTextField.text = FPCurrencyFormatter.printableCurrency(triggerAmount)
            }
            
            refreshHistoryRelatedViews(for: p)
            
            if let b = p.barcodeValue {
                self.barcodeTextField.text = b
            }
            
            self.selectedSupplier = p.supplier
        }
        
    }
    
    func refreshHistoryRelatedViews(for product: FPProduct) {
        boughtTextField.text = FPCurrencyFormatter.printableCurrency(product.bought ?? 0)
        remainingTextField.text = FPCurrencyFormatter.printableCurrency(product.remaining ?? 0)
        soldTextField.text = FPCurrencyFormatter.printableCurrency(product.sold ?? 0)
    }
    
    func applyConstraints() {
        
        // This is building indefinitely with no error messages if there are too many keys
        //        var views = [
        //            "productTableView": self.productTableView,
        //
        //        ]
        
        // tableView
        var tableViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[inventoryTableView]|", options: [], metrics: nil, views: ["inventoryTableView": self.inventoryTableView!])
        tableViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[inventoryTableView]|", options: [], metrics: nil, views: ["inventoryTableView": self.inventoryTableView!])
        self.view.addConstraints(tableViewConstraints)
        
        tableViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[productTableView]|", options: [], metrics: nil, views: ["productTableView": self.productTableView!])
        tableViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[productTableView]|", options: [], metrics: nil, views: ["productTableView": self.productTableView!])
        self.view.addConstraints(tableViewConstraints)
        
        self.assembleTableHeaderViewForProduct()
        if editProduct != nil {
            self.assembleTableHeaderViewForInventory()
        }
    }
    
    @discardableResult
    func addConstraintsToView(_ toView: UIView, forView view: UIView, placeBelowView belowView: UIView?, xPadding: Double, yPadding: Double, width: Double, height: Double, determinesHeaderHeight: Bool = false, heightMargin: Double = 20) -> [NSLayoutConstraint] {
        
        var viewWidthText = "[view]"
        var superviewText = "|"
        var xPaddingText = "-\(xPadding)-"
        
        if width > 0 { // if there's a width, don't stretch it to superview trailing/leading
            superviewText = ""
            viewWidthText = "[view(\(width))]"
        }
        
        if xPadding < 0 {
            xPaddingText = ""
        }
        
        let hFormat = "H:\(superviewText)\(xPaddingText)\(viewWidthText)\(xPaddingText)\(superviewText)"
        
        var viewHeightText = "[view]"
        
        if height > 0 {
            viewHeightText = "[view(\(height))]"
        }
        var vFormat = "V:[belowView]-\(yPadding)-\(viewHeightText)"
        if belowView == nil { // assume it's relative to superview
            vFormat = "V:|-\(yPadding)-\(viewHeightText)"
        }
        
        if determinesHeaderHeight {
            vFormat += "-\(heightMargin)-|"
        }
        
        var views = [String: Any]()
        views["view"] = view
        if let bv = belowView {
            views["belowView"] = bv
        }
        
        var constraints = NSLayoutConstraint.constraints(withVisualFormat: vFormat, options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: hFormat, options: [], metrics: nil, views: views)
        
        toView.addConstraints(constraints)
        return constraints
    }
    
    func addLeftViewForTextField(_ textField: UITextField) {
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: textField.frame.size.height))
        leftView.backgroundColor = UIColor.clear
        textField.leftView = leftView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.productTableView.tableHeaderView = self.productTableHeaderView
        self.inventoryTableView.tableHeaderView = self.inventoryTableHeaderView
        
        for textField in textFields {
            textField.delegate = self
            if textField.leftView == nil {
                textField.leftViewMode = UITextField.ViewMode.always
                self.addLeftViewForTextField(textField)
                
                if textField === self.priceTextField {
                    textField.rightViewMode = UITextField.ViewMode.always
                    let usdLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: textField.frame.size.height))
                    usdLabel.translatesAutoresizingMaskIntoConstraints = false
                    usdLabel.backgroundColor = UIColor.clear
                    usdLabel.font = UIFont(name: "HelveticaNeue", size: 17)
                    usdLabel.text = "USD "
                    usdLabel.textColor = FPColorRed
                    textField.rightView = usdLabel
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    @objc func textFieldEditingChanged(_ textField: UITextField) {
        textField.text = FPInputValidator.textAfterValidatingCurrencyText(textField.text!)
    }
    
    @objc func imagePressed() {
        let actionSheet = UIActionSheet(title: "Select option", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Camera roll", "Take a photo")
        actionSheet.tag = 1
        actionSheet.show(in: self.view)
    }
    
    func processInventoryOverlay(_ inventoryEnabled: Bool) {
        if inventoryEnabled {
            self.inventoryExpandableViewOverlayView?.removeFromSuperview()
            self.inventoryExpandableViewOverlayViewLabel?.removeFromSuperview()
        } else {
            
            // Yep, this happens
            self.inventoryExpandableViewOverlayView?.removeFromSuperview()
            self.inventoryExpandableViewOverlayViewLabel?.removeFromSuperview()
            
            self.inventoryExpandableViewOverlayView = UIView()
            self.inventoryExpandableViewOverlayViewLabel = self.genericHeaderLabel()
            
            let views: [String: Any] = [
                "inventoryExpandableViewOverlayView": self.inventoryExpandableViewOverlayView!,
                "inventoryExpandableView": self.inventoryExpandableView!,
                "inventoryExpandableViewOverlayViewLabel": self.inventoryExpandableViewOverlayViewLabel!
            ]
            
            self.inventoryExpandableViewOverlayView!.translatesAutoresizingMaskIntoConstraints = false
            self.inventoryExpandableViewOverlayView!.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            self.inventoryExpandableView.addSubview(self.inventoryExpandableViewOverlayView!)
            var inventoryExpandableViewOverlayViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[inventoryExpandableViewOverlayView]|", options: [], metrics: nil, views: views)
            inventoryExpandableViewOverlayViewConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[inventoryExpandableViewOverlayView]|", options: [], metrics: nil, views: views)
            self.inventoryExpandableView.superview!.addConstraints(inventoryExpandableViewOverlayViewConstraints)
            
            self.inventoryExpandableViewOverlayViewLabel!.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
            self.inventoryExpandableViewOverlayViewLabel!.textAlignment = .center
            self.inventoryExpandableViewOverlayViewLabel!.text = "Inventory Disabled"
            self.inventoryExpandableView.addSubview(self.inventoryExpandableViewOverlayViewLabel!)
            var inventoryExpandableViewOverlayViewLabelConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[inventoryExpandableViewOverlayViewLabel]|", options: [], metrics: nil, views: views)
            inventoryExpandableViewOverlayViewLabelConstraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[inventoryExpandableViewOverlayViewLabel]|", options: [], metrics: nil, views: views)
            self.inventoryExpandableView.superview!.addConstraints(inventoryExpandableViewOverlayViewLabelConstraints)
        }
    }
    
    @objc func segmentedValueChanged(_ segmented: UISegmentedControl) {
        if segmented === self.inventorySegmented {
            
            self.view.endEditing(true)
            
            let inventoryEnabled = self.inventorySegmented.selectedSegmentIndex == 0
            
            if let ep = self.editProduct {
                
                let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Processing"
                let completion = { (errMsg: String?, product: FPProduct?) -> Void in
                    hud?.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    } else {
                        self.editProduct?.mergeWithProduct(product!)
                        self.processInventoryOverlay(inventoryEnabled)
                    }
                }
                
                
                FPServer.sharedInstance.productCreateWithName(ep.name,
                    editProduct: ep,
                    searchId: ep.searchId!,
                    price: FPCurrencyFormatter.printableCurrency(ep.price),
                    measurement: ep.measurement,
                    image: nil,
                    productCategory: ep.category,
                    availabilityDate: nil,
                    onSaleNow: ep.onSaleNow,
                    hidden: ep.hidden,
                    trackInventory: inventoryEnabled,
                    supplier: self.selectedSupplier,
                    triggerAmount: ep.triggerAmount,
                    barcodeValue: ep.barcodeValue,
                    completion: completion)
            } else {
                self.processInventoryOverlay(inventoryEnabled)
            }
            
        } else if segmented === self.titleSegmented {
            self.view.endEditing(true)
            self.updateNavigationBar()
            if self.titleSegmented!.selectedSegmentIndex == 0 {
                self.inventoryTableView.isHidden = true
                self.productTableView.isHidden = false
            } else {
                self.inventoryTableView.isHidden = false
                self.inventoryTableView.reloadData()
                self.productTableView.isHidden = true
            }
        }
    }
    
    // MARK: - UIActionSheetDelegate
    func actionSheet(_ actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) {
        let buttonTitle = actionSheet.buttonTitle(at: buttonIndex)?.lowercased()
        if buttonTitle != "cancel" {
            if actionSheet.tag == 1 {
                let shouldUseCameraRoll = buttonTitle == "camera roll"
                let pickerController = UIImagePickerController()
                pickerController.allowsEditing = true
                pickerController.sourceType = shouldUseCameraRoll ? UIImagePickerController.SourceType.photoLibrary : UIImagePickerController.SourceType.camera
                pickerController.delegate = self
                self.present(pickerController, animated: true, completion: nil)
            } else if actionSheet.tag == 2 {
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
                    if let r = self.editProduct!.remaining {
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
        }
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.selectedImage = info[.editedImage] as? UIImage
        self.imageBtn.setBackgroundImage(self.selectedImage, for: .normal)
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === self.measurementTextField {
            let vc = FPSelectNamableViewController.selectNamableViewControllerWithDataSource(self.measurements, navigationBarTitle: "Select Measurement", objectSelectedHandler: { (object) -> Void in
                self.selectedMeasurement = object as? FPMeasurement
                _ = self.navigationController?.popViewController(animated: true)
            })
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        } else if textField === self.categoryTextField {
            let vc = FPProductCategoriesViewController.productCategoriesViewControllerWithCategorySelectedHandler({ (category) -> Void in
                self.selectedCategory = category
                _ = self.navigationController?.popViewController(animated: true)
            })
            navigationController!.pushViewController(vc, animated: true)
            return false
        } else if textField === self.supplierTextField {
            let vc = FPProductSuppliersViewController.productSuppliersViewControllerWithSupplierSelectedHandler { (supplier) -> Void in
                self.selectedSupplier = supplier
                
                if self.editProduct != nil {
                    let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                    hud?.removeFromSuperViewOnHide = true
                    hud?.labelText = "Processing"
                    let completion = {
                        [weak self] (errMsg: String?, product: FPProduct?) -> Void in
                        hud?.hide(false)
                        if errMsg != nil {
                            FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                        } else {
                            self?.editProduct!.supplier = product?.supplier
                        }
                    }
                    
                    FPServer.sharedInstance.productCreateWithName(self.editProduct!.name, editProduct: self.editProduct!, searchId: self.editProduct!.searchId!, price: "\(self.editProduct!.price)", measurement: self.editProduct!.measurement, image: nil, productCategory: self.editProduct!.category, availabilityDate: nil, onSaleNow: self.editProduct!.onSaleNow, hidden: self.editProduct!.hidden, trackInventory: self.editProduct!.trackInventory, supplier: self.selectedSupplier, triggerAmount: self.editProduct!.triggerAmount, barcodeValue: self.editProduct?.barcodeValue, completion: completion)
                }
                
                _ = self.navigationController?.popViewController(animated: true)
            }
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        } else if textField === barcodeTextField {
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
                        self?.editProduct!.barcodeValue = barcode
                        self?.barcodeTextField.text = product?.barcodeValue
                    }
                }
                
                FPServer.sharedInstance.productCreateWithName(self.editProduct!.name, editProduct: self.editProduct!, searchId: self.editProduct!.searchId!, price: "\(self.editProduct!.price)", measurement: self.editProduct!.measurement, image: nil, productCategory: self.editProduct!.category, availabilityDate: nil, onSaleNow: self.editProduct!.onSaleNow, hidden: self.editProduct!.hidden, trackInventory: self.editProduct!.trackInventory, supplier: self.editProduct!.supplier, triggerAmount: self.editProduct!.triggerAmount, barcodeValue: barcode, completion: completion)
            })
            self.navigationController?.pushViewController(vc, animated: true)
            return false
        } else if textField === self.boughtTextField || textField === self.remainingTextField || textField === self.soldTextField {
            return false
        }
        return true
    }
    
    // MARK: - Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        let tableView = self.productTableView.isHidden ? self.inventoryTableView : self.productTableView
        tableView?.contentInset = insets
        tableView?.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if let kbRect = (note.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    @objc func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
    // MARK: - UIAlertViewDelegate
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if alertView.buttonTitle(at: buttonIndex)?.lowercased() == "submit" {
            let text = alertView.textField(at: 0)!.text
            
            if let amount = NumberFormatter().number(from: text!)?.doubleValue, amount > 0 {
                let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Processing"
                FPServer.sharedInstance.productInventoryAddForProduct(self.editProduct!, amount: amount, type: alertView.tag) { (errMsg, product) -> Void in
                    hud?.hide(false)
                    if let e = errMsg {
                        FPAlertManager.showMessage(e, withTitle: "Error")
                    } else {
                        self.editProduct!.remaining = product?.remaining
                        self.editProduct!.sold = product?.sold
                        self.editProduct!.bought = product?.bought
                        self.populateSubviews()
                    }
                }
            } else {
                FPAlertManager.showMessage("Enter a valid amount", withTitle: "Error")
            }
        }
    }
}
