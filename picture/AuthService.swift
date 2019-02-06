//
//  AuthService.swift
//  picture
//
//  Created by Jason Goodney on 1/29/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseAuth
import JGProgressHUD

class AuthService {
    
    func sendPasswordReset(withEmail email: String, completion: @escaping ErrorCompletion) {
        
        let actionCodeSettings =  ActionCodeSettings.init()
        actionCodeSettings.handleCodeInApp = true
        
        //actionCodeSettings.url = URL(string: String(format: "https://www.example.com/?email=%@", email))
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
 
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
    
    func sendEmailVerifiction(currentUser: FirebaseUser, completion: @escaping ErrorCompletion) {
        
        let actionCodeSettings =  ActionCodeSettings.init()
        actionCodeSettings.handleCodeInApp = true
        
        actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
        
        currentUser.sendEmailVerification(completion: completion)
    }
}
