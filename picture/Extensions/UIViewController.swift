//
//  UIViewController+ChildViewController.swift
//  Wikio Ki
//
//  Created by Jason Goodney on 9/18/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

extension UIViewController {

    func add(_ child: UIViewController) {
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    func remove() {
        guard parent != nil else {
            return
        }
        
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }

    func hideKeyboardOnTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}

