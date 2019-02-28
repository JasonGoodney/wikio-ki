//
//  LoginFlowHandler.swift
//  Wikio Ki
//
//  Created by Jason Goodney on 9/18/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseAuth

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
        completion(Auth.auth().currentUser)
    }
    
    func handleLogout(withWindow window: UIWindow? = UIApplication.shared.keyWindow) {
        do {
            try Auth.auth().signOut()
            UserController.shared.dispose()
            
        
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
