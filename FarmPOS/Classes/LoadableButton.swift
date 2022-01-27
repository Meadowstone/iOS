//
//  LoadableButton.swift
//  Farm POS
//
//  Created by Luciano Polit on 26/1/22.
//  Copyright © 2022 Eugene Reshetov. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

class LoadableButton: UIButton {
    
    fileprivate let activityIndicator = UIActivityIndicatorView()
    fileprivate var titleMemory: String?
    fileprivate var imageMemory: UIImage?
    var isLoading = false {
        didSet {
            if isLoading {
                activityIndicator.startAnimating()
                titleMemory = titleLabel?.text
                imageMemory = imageView?.image
                setTitle(nil, for: .normal)
                setImage(nil, for: .normal)
            } else if oldValue {
                activityIndicator.stopAnimating()
                setTitle(titleMemory, for: .normal)
                setImage(imageMemory, for: .normal)
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints {
            $0.center.equalTo(snp.center)
        }
        activityIndicator.color = .black
        activityIndicator.hidesWhenStopped = true
    }
    
    override func setTitleColor(
        _ color: UIColor?,
        for state: UIControl.State
    ) {
        super.setTitleColor(color, for: state)
        activityIndicator.color = color
    }
    
}
