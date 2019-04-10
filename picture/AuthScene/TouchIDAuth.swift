//
//  TouchIDAuth.swift
//  picture
//
//  Created by Jason Goodney on 4/6/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import LocalAuthentication
import FirebaseAuth

class TouchIDAuth {
    
    private let lastAccessedEmailKey = "lastAccessedEmail"
    private let hasLoginKey = "hasLoginKey"
    
    public func saveAccountDetailsToKeychain(email: String, password: String) {
        if email.isEmpty || password.isEmpty {
            return
        }

        let hasLogin = UserDefaults.standard.bool(forKey: hasLoginKey)
        if !hasLogin {
            UserDefaults.standard.set(email, forKey: lastAccessedEmailKey)
        }
        
        
        do {
            let passwordItem = KeychainPasswordItem(
                service: KeychainConfiguration.serviceName,
                account: email,
                accessGroup: KeychainConfiguration.accessGroup)
            try passwordItem.savePassword(password)
        } catch {
            print("Error saving password to keychain")
        }
        
        UserDefaults.standard.set(true, forKey: hasLoginKey)
    }
    
    public func authenticateUserUsingTouchID(completion: @escaping (Error?) -> ()) {
        let context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: nil) {
            evaluateTouchIDAuthenticity(context: context, completion: completion)
        }
    }
    
    fileprivate func evaluateTouchIDAuthenticity(context: LAContext, completion: @escaping (Error?) -> ()) {
        guard let lastAccessedEmail = UserDefaults.standard.object(forKey: lastAccessedEmailKey) as? String else { return }
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: lastAccessedEmail) { (authSuccessful, authError) in
            if authSuccessful {
                self.loadPasswordFromKeychainAndAuthenticateUser(lastAccessedEmail, completion: completion)
            } else if let error = authError as? LAError {
                self.showError(error)
                completion(error)
            }
        }
    }
    
    fileprivate func loadPasswordFromKeychainAndAuthenticateUser(_ account: String, completion: @escaping (Error?) -> ()) {
        guard !account.isEmpty else { return }
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
        do {
            let storedPassword = try passwordItem.readPassword()
            authenticateUser(account, storedPassword, completion: completion)
        } catch KeychainPasswordItem.KeychainError.noPassword {
            print("No saved password")
            completion(KeychainPasswordItem.KeychainError.noPassword)
        } catch {
            print("Unhandled Touch ID auth error")
            completion(nil)
        }
    }
    
    #warning("This function repeats ")
    fileprivate func authenticateUser(_ email: String, _ password: String, completion: @escaping (Error?) -> ()) {
        Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
            if let error = err {
                completion(error)
            } else {
                let hasLogin = UserDefaults.standard.bool(forKey: "hasLoginKey")
                if !hasLogin {
                    let touchId = TouchIDAuth()
                    touchId.saveAccountDetailsToKeychain(email: email.lowercased(), password: password)
                }
                completion(nil)
                
            }
        }
        
    }
    
    fileprivate func showError(_ error: LAError) {
        var message: String = ""
        switch error.code {
        case LAError.authenticationFailed:
            message = "Authentication was not successful because the user failed to provide valid credentials. Please enter password to login."
            break
        case LAError.userCancel:
            message = "Authentication was canceled by the user"
            break
        case LAError.userFallback:
            message = "Authentication was canceled because the user tapped the fallback button"
            break
        case LAError.biometryNotEnrolled:
            message = "Authentication could not start because Touch ID has no enrolled fingers."
            break
        case LAError.passcodeNotSet:
            message = "Passcode is not set on the device."
            break
        case LAError.systemCancel:
            message = "Authentication was canceled by system"
            break
        default:
            message = error.localizedDescription
            break
        }
//        self.showPopupWithMessage(message)
        print(message)
    }
}
