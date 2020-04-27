//
//  FPProductCategoriesFooterView.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 28/05/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPProductCategoriesFooterView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    
    weak var delegate: FPProductCategoriesFooterViewDelegate?
    var categories: [NSDictionary] = [NSDictionary]() {
        didSet {
            self.collectionView.reloadData()
        }
    }
    
    class func productCategoriesFooterView() -> FPProductCategoriesFooterView {
        let view = Bundle.main.loadNibNamed("FPProductCategoriesFooterView", owner: nil, options: nil)?[0] as! FPProductCategoriesFooterView
        view.collectionView.register(UINib(nibName: "FPProductCategoryCollectionViewCell", bundle:nil), forCellWithReuseIdentifier:"FPProductCategoryCollectionViewCell")
        return view
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FPProductCategoryCollectionViewCell", for: indexPath) as! FPProductCategoryCollectionViewCell
        cell.category = categories[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.productCategoriesFooterView(self, didSelectCategory: categories[indexPath.row])
    }

}

@objc
protocol FPProductCategoriesFooterViewDelegate {
    func productCategoriesFooterView(_ footerView: FPProductCategoriesFooterView, didSelectCategory category: NSDictionary)
}
