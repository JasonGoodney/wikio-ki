//
//  UIApplication.swift
//  picture
//
//  Created by Jason Goodney on 2/27/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

extension UIApplication {
    func setStatusBar(hidden: Bool, duration: TimeInterval = 0.25) {
        
        let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        UIView.animate(withDuration: duration) {
            statusBarWindow?.alpha = hidden ? 0.0 : 1.0
        }
    }
}
