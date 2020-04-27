//
//  FPCreateCreditCardViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPCreateCreditCardViewController: FPRotationViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, CFTPaymentViewDelegate {
    
    var selectedCard: FPCreditCard?
    var creditCards = [FPCreditCard]()
    var creditCardSelectedHandler: ((_ card: FPCreditCard?, _ transactionToken: String?, _ last4: String?) -> Void)!
    var balancePayment = false
    var giftCardPayment = false
    var useCardFlightIfPossible = false
    var balanceSum = 0.0
    
    var editBtn: UIBarButtonItem!
    var createCardBtn: UIBarButtonItem!
    
    var cardFlightPaymentView : CFTPaymentView?
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var cardNumberTextField1: UITextField!
    @IBOutlet var cardNumberTextField2: UITextField!
    @IBOutlet var cardNumberTextField3: UITextField!
    @IBOutlet var cardNumberTextField4: UITextField!
    @IBOutlet var monthTextField: UITextField!
    @IBOutlet var yearTextField: UITextField!
    @IBOutlet var cvvTextField: UITextField!
    
    @IBOutlet var expDateLabel: UILabel!
    @IBOutlet var submitButton: UIButton!
    
    @IBOutlet var applicableBalanceBtn: UIButton!
    @IBOutlet weak var outstandingBalanceView: UIView!
    @IBOutlet weak var outstandingBalanceSwitch: UISwitch!
    
    @IBAction func switchValueChanged(_ sender: AnyObject) {
        if sender === outstandingBalanceSwitch {
            FPCartView.sharedCart().includeOutstandingBalance = outstandingBalanceSwitch.isOn
        }
    }
    
    @IBAction func submitPressed(_ sender: UIButton) {
        if (FPCardFlightManager.sharedInstance.statusCode != StatusCode.readerDisconnected && self.useCardFlightIfPossible)
        {
            let cardFlightCompletionHandler = { (sumPaid: NSDecimalNumber?, transactionToken: String?, last4: String?, errMsg: String?) -> Void in
                if let e = errMsg {
                    FPAlertManager.showMessage(e, withTitle: "Error")
                } else {
                    if self.balancePayment {
                        self.creditCardSelectedHandler(nil, transactionToken, last4)
                    } else {
                        var params: [String: Any] = ["method": 1 as AnyObject, "sumPaid": (sumPaid!), "transaction_token": transactionToken! as AnyObject]
                        if let l4 = last4 {
                            params["last_4"] = l4
                        }
                        NotificationCenter.default.post(name: Notification.Name(rawValue: FPPaymentMethodSelectedNotification), object: params)
                    }
                }
            }
            
            var sum = FPCartView.sharedCart().checkoutSum
            if balancePayment {
                sum = balanceSum
            }
            
            if (FPCustomer.activeCustomer() != nil && FPCardFlightManager.sharedInstance.cardFlightCard != nil) {
                FPServer.sharedInstance.createCardflightToken(FPCardFlightManager.sharedInstance.getCardToken(), forClientId: "\(FPCustomer.activeCustomer()!.id)", completion: { (errMsg) -> Void in
                    if (errMsg == nil) {
                        FPCardFlightManager.sharedInstance.chargeCardWithSum(sum, completion: cardFlightCompletionHandler)
                    } else {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    }
                })
            }
            else if (FPCustomer.activeCustomer() == nil && FPCardFlightManager.sharedInstance.cardFlightCard != nil)
            {
                // Charge card directly
                FPCardFlightManager.sharedInstance.chargeCardWithSum(sum, completion: cardFlightCompletionHandler)
            }
            else if (FPCardFlightManager.sharedInstance.cardFlightCard == nil)
            {
                FPAlertManager.showMessage("Card not detected", withTitle: "Warning")
            }
        } else {
            let cardNumber = cardNumberTextField1.text! + cardNumberTextField2.text! + cardNumberTextField3.text! + cardNumberTextField4.text!
            let expirationDate = monthTextField.text! + "/20" + yearTextField.text!
            if (cardNumber as NSString).length != 16 {
                FPAlertManager.showMessage("Enter valid card number", withTitle: "Error")
                return
            } else if (expirationDate as NSString).length != 7 {
                FPAlertManager.showMessage("Enter valid expiration date (same as indicated on your card)", withTitle: "Error")
                return
            } else if (cvvTextField.text! as NSString).length < 3 {
                FPAlertManager.showMessage("Enter valid cvv code", withTitle: "Error")
                return
            }
            
            var hud: MBProgressHUD!
            if FPCustomer.activeCustomer() != nil {
                let completion = { [weak self] (errMsg: String?) -> Void in
                    hud.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    } else {
                        self!.creditCardSelectedHandler(nil, nil, nil)
                    }
                }
                
                hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud.removeFromSuperViewOnHide = true
                hud.labelText = "Processing"
                FPServer.sharedInstance.creditCardCreateWithCardNumber(cardNumber, expirationDate: expirationDate, cvv: cvvTextField.text!, label: "", completion: completion)
            } else {
                let card = FPCreditCard()
                card.expirationDateString = expirationDate
                card.cardNumber = cardNumber
                card.cvv = cvvTextField.text
                self.creditCardSelectedHandler(card, nil, nil)
            }
        }
    }
    
    @IBAction func textFieldEditingChanged(_ textField: UITextField) {
        let length = (textField.text! as NSString).length
        if textField === cardNumberTextField1 && length == 4 {
            cardNumberTextField2.becomeFirstResponder()
        } else if textField === cardNumberTextField2 {
            if length == 4 {
                cardNumberTextField3.becomeFirstResponder()
            } else if length == 0 {
                cardNumberTextField1.becomeFirstResponder()
            }
        } else if textField === cardNumberTextField3 && length == 4 {
            if length == 4 {
                cardNumberTextField4.becomeFirstResponder()
            } else if length == 0 {
                cardNumberTextField2.becomeFirstResponder()
            }
        } else if textField === cardNumberTextField4 && length == 4 {
            if length == 4 {
                monthTextField.becomeFirstResponder()
            } else if length == 0 {
                cardNumberTextField3.becomeFirstResponder()
            }
        } else if textField === monthTextField && length == 2 {
            yearTextField.becomeFirstResponder()
        } else if textField === yearTextField && length == 2 {
            cvvTextField.becomeFirstResponder()
        } else if textField === cvvTextField && length == 4 {
            cvvTextField.resignFirstResponder()
        }
    }
    
    class func createCreditCardViewControllerWithCardSelectedHandler(_ handler: @escaping (_ card: FPCreditCard?, _ transactionToken: String?, _ last4: String?) -> Void) -> FPCreateCreditCardViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPCreateCreditCardViewController") as! FPCreateCreditCardViewController
        vc.creditCardSelectedHandler = handler
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applicableBalanceBtn?.titleLabel?.adjustsFontSizeToFitWidth = true
        self.applicableBalanceBtn?.titleLabel?.minimumScaleFactor = 0.7
        applicableBalanceBtn?.addTarget(self, action: #selector(FPCreateCreditCardViewController.applyBalancePressed), for: UIControlEvents.touchUpInside)
        
        // Check applicable balance
        if let customer = FPCustomer.activeCustomer(), FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) > 0 {
            var balance = FPCartView.sharedCart().sumWithTax
            if FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) < FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                balance = customer.balance
            } else if FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) >= FPCurrencyFormatter.intCurrencyRepresentation(FPCartView.sharedCart().sumWithTax) {
                balance = 0.00
            }
            FPCartView.sharedCart().applicableBalance = balance
            applicableBalanceBtn?.isHidden = false
            outstandingBalanceView.isHidden = true
        } else if let customer = FPCustomer.activeCustomer(), FPCurrencyFormatter.intCurrencyRepresentation(customer.balance) < 0  {
            applicableBalanceBtn?.isHidden = true
            outstandingBalanceView.isHidden = false
        } else {
            applicableBalanceBtn?.isHidden = true
            outstandingBalanceView.isHidden = true
        }
        
        self.updateApplicableBalanceBtn()
        
        // @Cardflight notifications
        NotificationCenter.default.addObserver(self, selector: #selector(FPCreateCreditCardViewController.updateCardStatus), name: NSNotification.Name(rawValue: FPReaderStatusChangedNotification), object: nil)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            view.backgroundColor = UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 245.0 / 255.0, alpha: 1.0)
        } else {
            preferredContentSize = CGSize(width: 640.0, height: 468.0)
        }
        
        if (FPCardFlightManager.sharedInstance.statusCode != StatusCode.readerDisconnected && self.useCardFlightIfPossible) {
            // Reader connected logic
            triggerCreateCard()
            self.cvvTextField.isHidden = true
            self.cardNumberTextField1.isEnabled = false
            self.cardNumberTextField2.isEnabled = false
            self.cardNumberTextField3.isEnabled = false
            self.cardNumberTextField4.isEnabled = false
            
            self.submitButton.isHidden = true
            
            /*
            self.cardFlightPaymentView = CFTPaymentView()
            self.cardFlightPaymentView?.delegate = self
            var width = self.view.frame.width - (self.cardNumberTextField1.frame.origin.x * 2)
            self.cardFlightPaymentView?.frame = CGRectMake(self.cardNumberTextField1.frame.origin.x, self.cardNumberTextField1.frame.origin.y, width, self.cardNumberTextField1.frame.size.height)
            self.cardFlightPaymentView?.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(self.cardFlightPaymentView!)
            */
            
            navigationItem.title = "Pay with card"
            navigationItem.rightBarButtonItems = nil
            navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Wait for swipe", style: .plain, target: self, action: #selector(FPCreateCreditCardViewController.waitForSwipe))]
            
            if (FPCardFlightManager.sharedInstance.cardFlightCard != nil) {
                navigationItem.title = "Pay with active card"
                self.cardNumberTextField4.text = FPCardFlightManager.sharedInstance.cardFlightCard!.last4;
                self.monthTextField.text = "\(FPCardFlightManager.sharedInstance.cardFlightCard!.expirationMonth)"
                self.yearTextField.text = "\(FPCardFlightManager.sharedInstance.cardFlightCard!.expirationYear)"
            } else {
            }
            if (FPCardFlightManager.sharedInstance.cardFlightCard != nil) {
                self.submitPressed(self.submitButton)
            }
        } else {
            
            navigationItem.title = "Credit Card"
            self.createCardBtn = UIBarButtonItem(title: "Create Credit Card", style: .plain, target: self, action: #selector(FPCreateCreditCardViewController.triggerCreateCard))
            self.editBtn = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(FPCreateCreditCardViewController.editPressed(_:)))
            navigationItem.rightBarButtonItems = [createCardBtn, editBtn]
            
            if FPCustomer.activeCustomer() != nil && FPCustomer.activeCustomer()!.hasCreditCard {
                let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud?.removeFromSuperViewOnHide = true
                hud?.labelText = "Fetching cards"
                FPServer.sharedInstance.creditCardsWithCompletion(false, completion: {[weak self] errMsg, cards, count in
                    hud?.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                    } else {
                        self!.creditCards = cards!
                        self!.tableView.reloadData()
                    }
                })
            } else {
                self.triggerCreateCard()
                navigationItem.rightBarButtonItems = nil
            }
        }
        
        for textField in [monthTextField, yearTextField, cvvTextField, cardNumberTextField1, cardNumberTextField2, cardNumberTextField3, cardNumberTextField4] {
            if let placeholder = textField?.placeholder {
                textField?.attributedPlaceholder = NSAttributedString(string : placeholder, attributes: [NSForegroundColorAttributeName: UIColor(red: 144.0 / 255.0, green: 144.0 / 255.0, blue: 144.0 / 255.0, alpha: 1.0)])
            }
        }

    }
    
    deinit {
        FPCartView.sharedCart().includeOutstandingBalance = false
        FPCardFlightManager.sharedInstance.cancelSwipe()
        NotificationCenter.default.removeObserver(self)
    }
    
    func editPressed(_ sender: UIBarButtonItem) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        if tableView.isEditing {
            sender.title = "Done"
        } else {
            sender.title = "Edit"
        }
    }
    
    func triggerCreateCard() {
        tableView.isHidden = !tableView.isHidden
        scrollView.isHidden = !scrollView.isHidden
        var title = ""
      
      if !self.useCardFlightIfPossible {
        if tableView.isHidden {
            navigationItem.title = "Create New Card"
            title = "Credit Cards"
            navigationItem.rightBarButtonItems = [createCardBtn]
        } else {
            navigationItem.title = "Credit Cards"
            title = "Create New Card"
            view.endEditing(true)
            navigationItem.rightBarButtonItems = [createCardBtn, editBtn]
        }
        createCardBtn.title = title
      }
    }
    
    func applyBalancePressed() {
        let vc = FPApplyBalanceViewController.applyBalanceViewControllerWithBalanceSelectedHandler {[weak self] (balance) -> Void in
            FPCartView.sharedCart().applicableBalance = balance
            self!.updateApplicableBalanceBtn()
            self!.navigationItem.title = "Purchase amount: $" + FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().checkoutSum)
            _ = self!.navigationController?.popViewController(animated: true)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func updateApplicableBalanceBtn() {
        // Removed check for allowcreditcardusage
        if let user = FPUser.activeUser(), user.farm != nil && FPCustomer.activeCustomer() != nil {
            applicableBalanceBtn?.setTitle("Applicable Balance: $\(FPCurrencyFormatter.printableCurrency(FPCartView.sharedCart().applicableBalance))", for: .normal)
            // Check if display is needed
            if FPCurrencyFormatter.intCurrencyRepresentation(FPCustomer.activeCustomer()!.balance) <= 0 {
                applicableBalanceBtn?.isHidden = true
            }
        }
        // Hide for balance payments and gift card payments
        if balancePayment || giftCardPayment {
            applicableBalanceBtn?.isHidden = true
            outstandingBalanceView.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)
        
        if !tableView.isHidden {
            //tableView.frame = CGRectMake(tableView.frame.origin.x, tableView.frame.origin.y, tableView.frame.width, tableView.frame.height - 50)
            //applicableBalanceBtn.frame = CGRectMake(144, 412, 353, 40)
        } else {
            
        }
    }
    
    // UITextField delegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string as NSString).length == 0 {
            return true
        }
        
        var limit = 4
        if textField === monthTextField || textField === yearTextField {
            limit = 2
        }
        
        let cs = CharacterSet(charactersIn: "0123456789")
        if (string as NSString).rangeOfCharacter(from: cs).length == 0 || ((textField.text! + string) as NSString).length > limit {
            return false
        }
        
        return true
    }
    
    // UITableView delegate and data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return creditCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
            cell!.backgroundColor = UIColor.clear
        }
        cell!.textLabel!.text = "Last 4: xxxx-xxxx-xxxx-" + creditCards[indexPath.row].last4
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let card = creditCards[indexPath.row]
        selectedCard = card
        
        let alert = UIAlertView()
        alert.delegate = self
        alert.title = "Would you like to pay with this card?"
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Yes")
        alert.show()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
            hud?.removeFromSuperViewOnHide = true
            hud?.labelText = "Deleting card"
            FPServer.sharedInstance.creditCardDelete(self.creditCards[indexPath.row], completion: { (errMsg) -> Void in
                hud?.hide(false)
                if let e = errMsg {
                    FPAlertManager.showMessage(e, withTitle: "Error")
                } else {
                    self.creditCards.remove(at: indexPath.row)
                    self.tableView.reloadData()
                    if self.creditCards.count == 0 && FPCustomer.activeCustomer() != nil {
                        FPCustomer.activeCustomer()!.hasCreditCard = false
                        self.triggerCreateCard()
                        self.navigationItem.rightBarButtonItems = nil
                    }
                }
            })
        }
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        var hud: MBProgressHUD!
        if buttonIndex == 1 {
            if selectedCard!.isDefault {
                self.creditCardSelectedHandler( selectedCard, nil, nil)
            } else {
                let completion = {[weak self] (errMsg: String?) -> Void in
                    hud.hide(false)
                    if errMsg != nil {
                        FPAlertManager.showMessage(errMsg!, withTitle: "Error")
                        self!.selectedCard = nil
                    } else {
                        self!.creditCardSelectedHandler(self!.selectedCard!, nil, nil)
                    }
                }
                hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
                hud.removeFromSuperViewOnHide = true
                hud.labelText = "Picking card"
                FPServer.sharedInstance.creditCardMakeDefault(selectedCard!, completion: completion)
            }
            
        } else {
            selectedCard = nil
        }
    }
    
    func updateCardStatus() {
        var status = FPCardFlightManager.sharedInstance.status
        
        switch (FPCardFlightManager.sharedInstance.statusCode!) {
        case .swipeTimedOut :
            status = "Wait for swipe"
            FPAlertManager.showMessage(FPCardFlightManager.sharedInstance.status, withTitle: "Warning")
        case .readerConnected :
            status = "Wait for swipe"
            self.cvvTextField.isHidden = true
            self.submitButton.isHidden = true
            self.cardNumberTextField1.isEnabled = false
            self.cardNumberTextField2.isEnabled = false
            self.cardNumberTextField3.isEnabled = false
            self.cardNumberTextField4.isEnabled = false
        case .readerDisconnected :
            self.cardNumberTextField4.text = ""
            self.monthTextField.text = ""
            self.yearTextField.text = ""
            self.view.endEditing(true)
            self.cardNumberTextField1.isEnabled = true
            self.cardNumberTextField2.isEnabled = true
            self.cardNumberTextField3.isEnabled = true
            self.cardNumberTextField4.isEnabled = true
            self.cvvTextField.isHidden = false
            self.submitButton.isHidden = false
            status = "Wait for swipe"
            navigationItem.rightBarButtonItems = nil
            FPAlertManager.showMessage(FPCardFlightManager.sharedInstance.status, withTitle: "Warning")
        case .recognizedCard:
            status = "Wait for swipe"
            self.cardNumberTextField4.text = FPCardFlightManager.sharedInstance.cardFlightCard!.last4;
            self.monthTextField.text = "\(FPCardFlightManager.sharedInstance.cardFlightCard!.expirationMonth)"
            self.yearTextField.text = "\(FPCardFlightManager.sharedInstance.cardFlightCard!.expirationYear)"
            self.submitPressed(self.submitButton)
        case .unrecognizedCard:
            self.cardNumberTextField4.text = ""
            self.monthTextField.text = ""
            self.yearTextField.text = ""
            FPAlertManager.showMessage("Card not recognized", withTitle: "Warning")
        default:
            _ = "Waiting for swipe"
        }
        status = "Wait for swipe"
        if (FPCardFlightManager.sharedInstance.statusCode != .readerDisconnected) {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(title: status, style: .plain, target: self, action: #selector(FPCreateCreditCardViewController.waitForSwipe))]
        }
    }
    
    func waitForSwipe() {
        switch (FPCardFlightManager.sharedInstance.statusCode!) {
        case .readerAttached, .readerConnecting, .readerDisconnected:
            _ = ""
        case .waitingForSwipe:
            FPCardFlightManager.sharedInstance.cancelSwipe()
            FPCardFlightManager.sharedInstance.waitForSwipe()
            navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Waiting for swipe...", style: .plain, target: self, action: nil)]
        default:
            FPCardFlightManager.sharedInstance.waitForSwipe()
            navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Waiting for swipe...", style: .plain, target: self, action: nil)]
        }
    }
    
    func keyedCardResponse(_ card: CFTCard?) {
        if (card != nil) {
            FPCardFlightManager.sharedInstance.cardFlightCard = card
        }
        else {
            
        }
    }
}
