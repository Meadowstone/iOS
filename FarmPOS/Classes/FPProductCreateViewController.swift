//
//  FPProductCreateViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/7/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD
import SDWebImage

class FPProductCreateViewController: FPRotationViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate {
    
    var product: FPProduct?
    var availabilityDatePicker = UIDatePicker()
    var productCategory: FPProductCategory?
    var image: UIImage?
    var selectedSupplier: FPProductSupplier? {
        didSet {
            if let s = selectedSupplier {
                self.supplierBtn.setTitle(s.name, for: .normal)
                self.supplierBtn.setTitleColor(UIColor.darkGray, for: .normal)
            } else {
                self.supplierBtn.setTitle("Product supplier (optional)", for: .normal)
                self.supplierBtn.setTitleColor(UIColor(red: 208.0 / 255.0, green: 208.0 / 255.0, blue: 212.0 / 255.0, alpha: 0.5), for: .normal)
            }
        }
    }
    var availableFrom: Date?
    var measurements = FPMeasurement.allMeasurements()!
    var selectedMeasurement: FPMeasurement!
    var completion: ((_ product: FPProduct?) -> Void)?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var searchIdTextField: UITextField!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var imgBtn: UIButton!
    @IBOutlet weak var categoryBtn: UIButton!
    @IBOutlet weak var supplierBtn: UIButton!
    @IBOutlet weak var availabilityDateView: UIView!
    @IBOutlet weak var availabilitySegmented: UISegmentedControl!
    @IBOutlet weak var inventorySegmented: UISegmentedControl!
    @IBOutlet weak var inventoryOptionsView: UIView!
    @IBOutlet weak var availabilityDateTextField: UITextField!
    @IBOutlet weak var triggerValueTextField: UITextField!
    @IBOutlet weak var visibilitySegmented: UISegmentedControl!
    @IBOutlet weak var measurementPickerView: UIPickerView!
    @IBOutlet weak var availabilityViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var measurementLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var inventoryOptionsViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func imagePressed(_ sender: AnyObject) {
        let actionSheet = UIActionSheet()
        actionSheet.title = "Select option"
        actionSheet.addButton(withTitle: "Camera roll")
        actionSheet.addButton(withTitle: "Take a photo")
        actionSheet.addButton(withTitle: "Cancel")
        actionSheet.cancelButtonIndex = 2
        actionSheet.delegate = self
        actionSheet.show(in: view)
    }
    
    @IBAction func categoryPressed(_ sender: AnyObject) {
        let completion = {
            [weak self] (category: FPProductCategory) -> Void in
            self!.categoryBtn.setTitle(category.name, for: .normal)
            self!.categoryBtn.setTitleColor(UIColor.darkGray, for: .normal)
            self!.productCategory = category
            self!.navigationController!.popViewController(animated: true)
        }
        let vc = FPProductCategoriesViewController.productCategoriesViewControllerWithCategorySelectedHandler(completion)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func supplierPressed(_ sender: AnyObject) {
        let vc = FPProductSuppliersViewController.productSuppliersViewControllerWithSupplierSelectedHandler { (supplier) -> Void in
            self.selectedSupplier = supplier
            _ = self.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func segmentedValueChanged(_ sender: UISegmentedControl) {
        if (sender === self.availabilitySegmented) {
            view.endEditing(true)
            expandAvailabilityDateView(expand: sender.selectedSegmentIndex != 0, true)
        } else if (sender === self.inventorySegmented) {
            let expand = self.inventorySegmented.selectedSegmentIndex == 0
            self.expandInventoryOptionsView(expand: expand, true)
        }
    }
    
    @IBAction func textFieldEditingChanged(_ sender: UITextField) {
        sender.text = FPInputValidator.textAfterValidatingCurrencyText(sender.text!)
    }
    
    
    class func productCreateViewControllerWithCompletion(_ completion: ((_ product: FPProduct?) -> Void)?, product: FPProduct?) -> FPProductCreateViewController {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "FPProductCreateViewController") as! FPProductCreateViewController
        vc.completion = completion
        vc.product = product
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register observers
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductCreateViewController.keyboardWillChangeFrame(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPProductCreateViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // Customize controller appearance
        UIApplication.shared.statusBarStyle = .lightContent
        
        navigationController!.navigationBar.isTranslucent = false
        
        // Set title and Cancel Save buttons
        navigationItem.title = "New Product"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPProductCreateViewController.cancelPressed))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(FPProductCreateViewController.savePressed))
        
        // Apply text field offsets, add USD label
        for textField in [nameTextField, searchIdTextField, priceTextField, availabilityDateTextField, triggerValueTextField] {
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
        
        // Preselect measurement
        selectedMeasurement = measurements[0]
        
        // Apply bordering to image button
        imgBtn.layer.borderColor = FPColorGreen.cgColor
        imgBtn.layer.borderWidth = 1.0
        
        scrollView.keyboardDismissMode = .onDrag
        
        availabilitySegmented.tintColor = UINavigationBar.appearance().barTintColor
        visibilitySegmented.tintColor = UINavigationBar.appearance().barTintColor
        inventorySegmented.tintColor = UINavigationBar.appearance().barTintColor
        expandAvailabilityDateView(expand: false, false)
        
        // Select maximum searchId among all products + 1
        var num = -1
        for product in FPProduct.allProducts()! {
            if let s = product.searchId {
                if let n = Int(s) {
                    num = max(num, n)
                }
            }
        }
        searchIdTextField.text = "\(num + 1)"
        
        // Configure availability date text field and picker
        availabilityDatePicker.datePickerMode = .date
        
        var comps = DateComponents()
        comps.month = 1
        let cal = Calendar.current
        let nDate = (cal as NSCalendar).date(byAdding: comps, to: Date(), options: NSCalendar.Options(rawValue: 0))
        availabilityDatePicker.minimumDate = nDate
        
        if availableFrom == nil {
            availableFrom = nDate
        }
        
        availabilityDatePicker.date = availableFrom!
        availabilityDatePicker.addTarget(self, action: #selector(FPProductCreateViewController.dateChanged(_:)), for: .valueChanged)
        availabilityDateTextField.inputView = availabilityDatePicker
        availabilityDatePicker.sendActions(for: .valueChanged)
        
        // If editing product - prepopulate everything with values
        if let p = product {
            navigationItem.title = p.name
            nameTextField.text = p.name
            productCategory = p.category
            
            selectedMeasurement = p.measurement
            //            var mIndex = 0
            let fm = measurements.filter({ return $0.id == p.measurement.id })
            if fm.count > 0 {
                measurementPickerView.selectRow((measurements as NSArray).index(of: fm[0]), inComponent: 0, animated: false)
            }
            
            searchIdTextField.text = p.searchId
            if let url = p.imageURL {
                imgBtn.sd_setBackgroundImage(with: url, for: .normal)
            }
            priceTextField.text = FPCurrencyFormatter.printableCurrency(p.price)
            categoryBtn.setTitleColor(UIColor.darkGray, for: .normal)
            categoryBtn.setTitle(p.category.name, for: .normal)
            availabilitySegmented.selectedSegmentIndex = p.onSaleNow ? 0 : 1
            visibilitySegmented.selectedSegmentIndex = p.hidden ? 1 : 0
            inventorySegmented.selectedSegmentIndex = p.trackInventory ? 0 : 1
            self.expandInventoryOptionsView(expand: p.trackInventory, false)
            if let triggerAmount = p.triggerAmount {
                self.triggerValueTextField.text = FPCurrencyFormatter.printableCurrency(triggerAmount)
            }
            
            if let supplier = p.supplier {
                supplierBtn.setTitle(supplier.name, for: .normal)
                supplierBtn.setTitleColor(UIColor.darkGray, for: .normal)
            }
            
            availabilitySegmented.sendActions(for: .valueChanged)
            if let af = p.availableFrom {
                availableFrom = af as Date
                let f = DateFormatter()
                f.dateFormat = "MMM yyyy"
                availabilityDateTextField.text = f.string(from: af as Date)
            }
        }
    }
    
    func expandInventoryOptionsView(expand: Bool, _ animated: Bool) {
        var constant: CGFloat = 0.0
        if expand {
            constant = 156.0
        }
        self.inventoryOptionsView.isHidden = !expand
        self.inventoryOptionsViewHeightConstraint.constant = constant
        view.setNeedsUpdateConstraints()
        if animated {
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func expandAvailabilityDateView(expand: Bool, _ animated: Bool) {
        //        let height: CGFloat = expand ? 76.0 : 0.0
        //        let offset: CGFloat = height == 0.0 ? 0.0 : 8.0
        //
        //        availabilityViewHeightConstraint.constant = height
        //        measurementLabelTopConstraint.constant = offset
        //        view.setNeedsUpdateConstraints()
        //        if animated {
        //            UIView.animateWithDuration(0.25, animations: { () -> Void in
        //                self.view.layoutIfNeeded()
        //            })
        //        }
    }
    
    func cancelPressed() {
        completion?(nil)
    }
    
    func savePressed() {
        var errors = ""
        if (nameTextField.text! as NSString).length == 0 {
            errors = "\nEnter name"
        }
        if (searchIdTextField.text! as NSString).length == 0 {
            errors = "\nEnter search id"
        }
        if image == nil && product == nil {
            errors = "\nSelect picture"
        }
        if productCategory == nil {
            errors = "\nSelect product category"
        }
        
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        let n: NSNumber? = nf.number(from: priceTextField.text!)
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
        hud?.labelText = "Creating product"
        let completion = {
            [weak self] (errMsg: String?, product: FPProduct?) -> Void in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self!.completion?(product)
            }
        }
        
        availabilitySegmented.selectedSegmentIndex = 0
        
        var triggerAmount: Double?
        if triggerValueTextField.text!.count > 0 {
            triggerAmount = NumberFormatter().number(from: triggerValueTextField.text!)?.doubleValue
        }
        
        let trackInventory = self.inventorySegmented.selectedSegmentIndex == 0
        if !trackInventory {
            triggerAmount = nil
            selectedSupplier = nil
        }
        
        FPServer.sharedInstance.productCreateWithName(nameTextField.text!, editProduct: product, searchId: searchIdTextField.text!, price: priceTextField.text!, measurement: selectedMeasurement, image: image, productCategory: productCategory!, availabilityDate: availableFrom!, onSaleNow: availabilitySegmented.selectedSegmentIndex == 0, hidden: visibilitySegmented.selectedSegmentIndex == 1, trackInventory: trackInventory, supplier: self.selectedSupplier, triggerAmount: triggerAmount, barcodeValue: self.product?.barcodeValue, completion: completion)
    }
    
    //MARK: Date picker
    func dateChanged(_ sender: UIDatePicker) {
        availableFrom = sender.date
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        availabilityDateTextField.text = f.string(from: availableFrom!)
    }
    
    //MARK: Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        scrollView.contentInset = insets
        scrollView.scrollIndicatorInsets = insets
    }
    
    func keyboardWillChangeFrame(_ note: Notification) {
        if let kbRect = (note.userInfo![UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue {
            let insets = UIEdgeInsetsMake(0, 0, kbRect.size.height, 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }
    
    // MARK: UIPickerView data source & delegate
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return measurements.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30.0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let m = measurements[row]
        return m.shortName + " - " + m.longName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedMeasurement = measurements[row]
    }
    
    // MARK: UITextField delegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameTextField {
            searchIdTextField.becomeFirstResponder()
        }
        return false
    }
    
    // MARK: UIActionSheet delegate
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        if buttonIndex != 2 {
            let pickerController = UIImagePickerController()
            pickerController.allowsEditing = true
            pickerController.sourceType = buttonIndex == 0 ? UIImagePickerControllerSourceType.photoLibrary : UIImagePickerControllerSourceType.camera
            present(pickerController, animated: true, completion: {
                [weak self] in
                pickerController.delegate = self!
            })
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        image = (info[UIImagePickerControllerEditedImage] as? UIImage)!
        imgBtn.setBackgroundImage(image, for: .normal)
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}
