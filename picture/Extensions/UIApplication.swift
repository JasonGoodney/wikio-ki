//
//  UIApplication.swift
//  picture
//
//  Created by Jason Goodney on 2/27/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import UserNotifications

extension UIApplication {
    func setStatusBar(hidden: Bool, duration: TimeInterval = 0.25) {
        
        let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        UIView.animate(withDuration: duration) {
            statusBarWindow?.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    func decrementBadgeNumber() {
        if UIApplication.shared.applicationIconBadgeNumber - 1 < 0 {
            return
        }
        setBadgeIndicator(badgeCount: UIApplication.shared.applicationIconBadgeNumber - 1)
    }
    
    func incrementBadgeNumber() {
        setBadgeIndicator(badgeCount: UIApplication.shared.applicationIconBadgeNumber + 1)
    }
    
    fileprivate func setBadgeIndicator(badgeCount: Int) {
        let application = UIApplication.shared
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
        } else {
            application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil))
        }
        application.registerForRemoteNotifications()
        application.applicationIconBadgeNumber = badgeCount
    }
}
