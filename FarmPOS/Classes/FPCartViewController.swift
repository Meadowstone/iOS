//
//  FPCartViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 8/4/14.
//  Copyright (c) 2014 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPCartViewController: FPRotationViewController, FPCartViewDelegate, FPProductViewControllerDelegate {
    
    var cartView = FPCartView.sharedCart()
    
    class func cartViewController() -> FPCartViewController {
        let vc = FPStoryboardManager.productsAndCartStoryboard().instantiateViewController(withIdentifier: "FPCartViewController") as! FPCartViewController
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Cart"
        cartView.frame = view.bounds
        cartView.delegate = self
        view.addSubview(cartView)
        
        FPServer.sharedInstance.syncAPNsToken()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "add_btn"), style: .plain, target: self, action: #selector(FPCartViewController.addPressed))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        cartView.tableView.reloadData()
        cartView.updateSum()
    }
    
    @objc func addPressed() {
//        let vc = FPCategoriesViewController.categoriesViewController()
        let vc = FPProductsViewController.productsViewControllerForCategory(nil)
        navigationController!.pushViewController(vc, animated: true)
    }
    
    func unassignPressed() {
        FPCustomer.setActiveCustomer(nil)
        FPOrder.setActiveOrder(nil)
        FPCartView.sharedCart().resetCart()
        navigationItem.rightBarButtonItem = nil
    }
    
    //MARK: FPCartView delegate
    func cartViewDidCheckout(_ cartView: FPCartView) {
        if cartView.cartProducts.count > 0 {
            let vc = FPCheckoutViewController.checkoutViewController()
            navigationController!.pushViewController(vc, animated: true)
        }
    }
    
    func cartViewDidSelectProduct(_ cartView: FPCartView, p: FPCartProduct) {
        let vc = FPProductViewController.productNavigationViewControllerForCartProduct(p, processingCSAId: nil, delegate: self, updating: true)
        present(vc, animated: true, completion: nil)
    }
    
    //MARK: ProductViewController delegate
    func productViewControllerDidAdd(_ pvc: FPProductViewController, cartProduct: FPCartProduct) {
        FPCartView.sharedCart().addCartProduct(cartProduct, updating: pvc.updating)
        dismiss(animated: true, completion: nil)
    }
    
    func productViewControllerDidRemove(_ pvc: FPProductViewController, cartProduct: FPCartProduct) {
        FPCartView.sharedCart().deleteCartProduct(cartProduct)
        dismiss(animated: true, completion: nil)
    }
    
    func productViewControllerDidCancel(_ pvc: FPProductViewController) {
        dismiss(animated: true, completion: nil)
    }

}
