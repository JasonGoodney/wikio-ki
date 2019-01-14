//
//  AuthValidation.swift
//  picture
//
//  Created by Jason Goodney on 1/10/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

struct AuthValidation {
    
    static func isValidUsername(_ username: String, completion: @escaping (RegisterError?) -> Void) {
        
        do
        {
            let regex = try NSRegularExpression(pattern: "^[a-z]([0-9a-zA-Z\\_]{3,15})$", options: .caseInsensitive)
            if regex.matches(in: username, options: [], range: NSMakeRange(0, username.count)).count > 0 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                let dbs = DatabaseService()
                dbs.fetchTakenUsername(username: username) { (taken) in
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    if taken {
                        let registerError = RegisterError.init(msg: "Username already exists.")
                        completion(registerError)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                let registerError = RegisterError.init(msg: "Username must be 3 or more characters,\nstarting with a letter")
                completion(registerError)
            }
        }
        catch {}
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
}
