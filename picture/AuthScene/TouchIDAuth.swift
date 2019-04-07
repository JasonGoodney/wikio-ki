//
//  TouchIDAuth.swift
//  picture
//
//  Created by Jason Goodney on 4/6/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import LocalAuthentication

class TouchIDAuth {
    
    private let lastAccessedEmailKey = "lastAccessedEmail"
    
    public func saveAccountDetailsToKeychain(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            return
        }
        #warning("ask to set email")
        UserDefaults.standard.set(email, forKey: lastAccessedEmailKey)
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: email, accessGroup: KeychainConfiguration.accessGroup)
        do {
            try passwordItem.savePassword(password)
        } catch {
            print("Error saving password to keychain")
        }
    }
    
    public func authenticateUserUsingTouchID() {
        let context = LAContext()
        if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: nil) {
            evaluateTouchIDAuthenticity(context: context)
        }
    }
    
    fileprivate func evaluateTouchIDAuthenticity(context: LAContext) {
        guard let lastAccessedEmail = UserDefaults.standard.object(forKey: lastAccessedEmailKey) as? String else { return }
        context.evaluatePolicy(LAPolicy.deviceOwnerAuthentication, localizedReason: lastAccessedEmail) { (authSuccessful, authError) in
            if authSuccessful {
                self.loadPasswordFromKeychainAndAuthenticateUser(lastAccessedEmail)
            } else if let error = authError as? LAError {
                self.showError(error)
            }
        }
    }
    
    fileprivate func loadPasswordFromKeychainAndAuthenticateUser(_ account: String) {
        guard !account.isEmpty else { return }
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
        do {
            let storedPassword = try passwordItem.readPassword()
            //authenticateUser(storedPassword)
        } catch KeychainPasswordItem.KeychainError.noPassword {
            print("No saved password")
        } catch {
            print("Unhandled Touch ID auth error")
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
