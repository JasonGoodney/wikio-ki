//
//  LoginFlowHandler.swift
//  Wikio Ki
//
//  Created by Jason Goodney on 9/18/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseMessaging
import FirebaseInstanceID

protocol LoginFlowHandler {
    func handleLogin(withWindow window: UIWindow?, completion: @escaping (FirebaseUser?) -> Void)
    func handleLogout(withWindow window: UIWindow?)
}

extension LoginFlowHandler {
    
    func handleLogin(withWindow window: UIWindow? = UIApplication.shared.keyWindow, completion: @escaping (FirebaseUser?) -> Void) {
        if let _ = Auth.auth().currentUser {
            showMain(withWindow: window)
        } else {
            showLogin(withWindow: window)
        }
        
        if let uid = Auth.auth().currentUser?.uid, let fcmToken = Messaging.messaging().fcmToken {
            let dbs = DatabaseService()
            let ref = Firestore.firestore().collection(DatabaseService.Collection.users).document(uid)
            
            dbs.updateData(ref, withFields: [User.Keys.fcmToken: fcmToken]) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("Updates fcmtoken for: \(uid)")
            }
        }
        
        completion(Auth.auth().currentUser)
    }
    
    func handleLogout(withWindow window: UIWindow? = UIApplication.shared.keyWindow) {
        do {
            
            try Auth.auth().signOut()
            UserController.shared.dispose()
    
            InstanceID.instanceID().deleteID { (error) in
                if let error = error {
                    print(error)
                }
        
                print("Deleted fcm token")
                
                
            }
            InstanceID.instanceID().instanceID { (result, error) in
                if let error = error {
                    print("Error fetching remote instange ID: \(error)")
                } else {
                    print("Remote instance ID token: \(String(describing: result?.token))")
                }
            }
            Messaging.messaging().shouldEstablishDirectChannel = true
        
        } catch let error {
            print("Error signing out of Firebase \(error)")
        }
        
        showLogin(withWindow: window)
    }
    
    func showMain(withWindow window: UIWindow?) {
        window?.subviews.forEach { $0.removeFromSuperview() }
        window?.rootViewController = nil
        window?.rootViewController = UINavigationController(rootViewController: FriendsListViewController())
        window?.makeKeyAndVisible()
    }
    
    func showLogin(withWindow window: UIWindow?) {
        window?.rootViewController = nil
        window?.rootViewController = UINavigationController(rootViewController: RegisterViewController())
        window?.makeKeyAndVisible()
    }
    
}
