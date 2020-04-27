//
//  FPGiftCardsViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit
import MBProgressHUD

class FPGiftCardsViewController: FPRotationViewController, UITableViewDataSource, UITableViewDelegate, FPGiftCardCellDelegate {
    
    var giftCards = [FPGiftCard]()
    var cardBoughtHandler: (() -> Void)!
    
    @IBOutlet var tableView: UITableView!
    
    
    class func giftCardsViewControllerWithContentSize(_ cs: CGSize, cardBoughtHandler:@escaping () -> Void) -> FPGiftCardsViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPGiftCardsViewController") as! FPGiftCardsViewController
        vc.preferredContentSize = cs
        vc.cardBoughtHandler = cardBoughtHandler
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Gift Cards"
        
        tableView.rowHeight = 51.0
        tableView.register(UINib(nibName: "FPGiftCardCell", bundle: nil), forCellReuseIdentifier: "FPGiftCardCell")
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let hud = MBProgressHUD.showAdded(to: FPAppDelegate.instance().window!, animated: false)
        hud?.removeFromSuperViewOnHide = true
        hud?.labelText = "Loading"
        FPServer.sharedInstance.giftCardsWithCompletion({[weak self] errMsg, giftCards in
            hud?.hide(false)
            if errMsg != nil {
                FPAlertManager.showMessage(errMsg!, withTitle: "Error")
            } else {
                self!.giftCards = giftCards!
                self!.tableView.reloadData()
            }
        })
    }
    
    func processGiftCard(_ giftCard: FPGiftCard) {
        let vc = FPBuyGiftCardViewController.buyGiftCardViewControllerWithGiftCard(giftCard, cardBoughtHandler: cardBoughtHandler)
        vc.preferredContentSize = preferredContentSize
        navigationController!.pushViewController(vc, animated: true)
    }
    
    // UITableView delegate and data source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return giftCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FPGiftCardCell") as! FPGiftCardCell
        cell.giftCard = giftCards[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        processGiftCard(giftCards[indexPath.row])
    }
    
    // FPGiftCardCellDelegate
    func giftCardCellDidPressBuy(_ cell: FPGiftCardCell) {
        processGiftCard(cell.giftCard)
    }
    
}
