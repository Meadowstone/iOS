//
//  FPAddNotesViewController.swift
//  Farm POS
//
//  Created by Eugene Reshetov on 23/07/2015.
//  Copyright (c) 2015 Eugene Reshetov. All rights reserved.
//

import UIKit

class FPAddNotesViewController: FPRotationViewController {
    
    var completion: ((_ text: String) -> Void)!
    var textView: UITextView!
    
    class func addNotesViewControllerWithCompletion(_ completion: @escaping (_ text: String) -> Void) -> FPAddNotesViewController {
        let vc = FPAddNotesViewController()
        vc.completion = completion
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Add Notes"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(FPAddNotesViewController.addPressed))
        
        textView = UITextView(frame: self.view.bounds)
        textView.font = UIFont(name: "HelveticaNeue", size: 17.0)
        self.view.addSubview(textView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(FPAddNotesViewController.keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FPAddNotesViewController.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        textView.becomeFirstResponder()
    }
    
    @objc func addPressed() {
        completion(self.textView.text!)
    }
    
    //MARK: Notifications and scroll view
    func setScrollViewInsets(_ insets: UIEdgeInsets) {
        textView.contentInset = insets
        textView.scrollIndicatorInsets = insets
    }
    
    @objc func keyboardWillChangeFrame(_ note: Notification) {
        if var kbRect = (note.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as AnyObject).cgRectValue {
            kbRect = FPAppDelegate.instance().window!.convert(kbRect, to: view)
            let insets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
            self.setScrollViewInsets(insets)
        }
    }
    
    @objc func keyboardWillHide(_ note: Notification) {
        self.setScrollViewInsets(UIEdgeInsets.zero)
    }

}
