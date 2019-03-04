//
//  AppDelegate.swift
//  picture
//
//  Created by Jason Goodney on 12/8/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseMessaging
import Digger
import SDWebImage
import UserNotifications

extension UIApplication {
    var isBackground: Bool {
        return UIApplication.shared.applicationState == .background
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LoginFlowHandler {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    var backgroundUploadTask: UIBackgroundTaskIdentifier!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
    
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()

        handleLogin(withWindow: window) { (_) in }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        DiggerCache.cleanDownloadFiles()
        DiggerCache.cleanDownloadTempFiles()
    }

    // MARK: - Remote Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
         if let aps = userInfo["aps"] as? NSDictionary {
            if let alert = aps["alert"] as? NSDictionary {
                if let badge = alert["badge"] as? NSString, badge.integerValue == 1 {
                    UIApplication.shared.incrementBadgeNumber()
                }
            }
        }
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([.alert, .badge, .sound])
    }
    
    func attemptRegisterForNotifications(_ application: UIApplication) {
        print("Attempting to regiser APNS")
        
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        
            UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted, error) in
                if let error = error {
                    print("Failed to request APSN auth:", error)
                    return
                }
                
                if granted {
                    print("Auth granted")
                } else {
                    print("Auth denied")
                }
            }
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let badge = userInfo["badge"] as? Int {
            print(badge)
            let badgeNumber = UIApplication.shared.applicationIconBadgeNumber
//            UIApplication.shared.applicationIconBadgeNumber = badge + badgeNumber
        }
        
        if let chatUid = userInfo["chat"] as? String {
            print(chatUid)
        }
    }
    

}


// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Registered with FCM with token: ", fcmToken)
    }
    
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
}

// MARK: - Handle Background Tasks
extension AppDelegate {
    func doBackgroundTask() {
        beginBackgroundUpload()
        
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            self.endBackgroundUpload()
        }
    }
    
    func beginBackgroundUpload() {
        backgroundUploadTask = UIApplication.shared.beginBackgroundTask(withName: "UploadMedia", expirationHandler: {
            self.endBackgroundUpload()
        })
    }
    
    func endBackgroundUpload() {
        UIApplication.shared.endBackgroundTask(backgroundUploadTask)
        backgroundUploadTask = UIBackgroundTaskIdentifier.invalid
    }
}
