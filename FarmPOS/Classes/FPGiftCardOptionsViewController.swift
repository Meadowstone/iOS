//
//  FPGiftCardOptionsViewController.swift
//  FarmPOS
//
//  Created by Eugene Reshetov on 7/11/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//


class FPGiftCardOptionsViewController: FPRotationViewController {
    
    var closeBlock: (() -> Void)!

    @IBAction func buyPressed(_ sender: AnyObject) {
        if !FPUser.activeUser()!.farm!.canUseCreditCard {
            FPAlertManager.showMessage("This farm is not configured to use credit cards.", withTitle: "Error")
            return
        }
        let vc = FPGiftCardsViewController.giftCardsViewControllerWithContentSize(preferredContentSize, cardBoughtHandler:closeBlock)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func redeemPressed(_ sender: AnyObject) {
        let vc = FPRedeemGiftCardViewController.redeemGiftCardViewControllerWithDidRedeemHandler(closeBlock)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    @IBAction func manageBalancePressed(_ sender: AnyObject) {
        let vc = FPManageBalanceViewController.manageBalanceViewControllerWithCompletion(closeBlock)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    
    class func giftCardOptionsNavigationViewControllerWithCloseBlock(_ closeBlock:@escaping () -> Void) -> UINavigationController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPGiftCardOptionsViewController") as! FPGiftCardOptionsViewController
        vc.closeBlock = closeBlock
        let nc = UINavigationController(rootViewController: vc)
        return nc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController!.navigationBar.barStyle = .black;
        navigationController!.navigationBar.isTranslucent = false;

        navigationItem.title = "Gift Cards / Balance"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Gift Card FAQ", style: .plain, target: self, action: #selector(FPGiftCardOptionsViewController.giftCardFAQPressed))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(FPGiftCardOptionsViewController.cancelPressed))
        preferredContentSize = CGSize(width: 640, height: 468)
    }
    
    @objc func giftCardFAQPressed() {
        let vc = UIViewController()
        vc.preferredContentSize = preferredContentSize
        vc.loadView()
        
        let wv = UIWebView(frame: vc.view.bounds)
        wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wv.scalesPageToFit = true
        if let path = Bundle.main.path(forResource: "gift_card_FAQ", ofType: "html") {
            if let data = FileManager.default.contents(atPath: path) {
                var htmlString = String(data: data, encoding: .utf8)!
                htmlString = htmlString.replacingOccurrences(of: "Ski Hearth Farmstand", with: FPUser.activeUser()!.farm!.name)
                wv.loadHTMLString(htmlString as String, baseURL: nil)
            }
        }
        vc.view.addSubview(wv)
        vc.navigationItem.title = "Gift Card FAQ"
        vc.view.backgroundColor = UIColor.white
        
        self.navigationController!.pushViewController(vc, animated: true)
    }
    
    @objc func cancelPressed() {
        closeBlock()
    }

}
