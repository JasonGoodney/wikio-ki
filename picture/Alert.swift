//
//  Alert.swift
//  picture
//
//  Created by Jason Goodney on 12/30/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

extension UIViewController {
    func errorAlert(alertTitle: String? = nil, alertMessage: String? = nil, completion: @escaping () -> Void = { }) {
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (_) in
            completion()
        }
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func logoutActionSheet(completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to logout?", preferredStyle: .actionSheet)
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { (_) in
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func unblockActionSheet(completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to unblock this user?", preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "Unblock", style: .default) { (_) in
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func userDescructionActionSheet(completion: @escaping (UserDestructionType) -> Void) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let bestFriendAction = UIAlertAction(title: "Best Friend", style: .default) { (_) in
            completion(.bestFriend)
        }
        let blockAction = UIAlertAction(title: "Block", style: .destructive) { (_) in
            completion(.block)
        }
        
        let removeAction = UIAlertAction(title: "Remove Friend", style: .destructive) { (_) in
            completion(.remove)
        }
        
        let reportAction = UIAlertAction(title: "Report", style: .destructive) { (_) in
            completion(.report)
        } 
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(.none)
        }
        
        alertController.addAction(bestFriendAction)
        alertController.addAction(removeAction)
        alertController.addAction(blockAction)
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func sendVerifyEmailAlert(to email: String, completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "Send email verification", message: email, preferredStyle: .alert)
        
        let sendAction = UIAlertAction(title: "Send", style: .default) { (_) in
            completion(true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        
        alertController.addAction(sendAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func destructiveAlert(alertTitle: String, actionTitle: String, completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        
        let destructiveAction = UIAlertAction(title: actionTitle, style: .destructive) { _ in
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false)
        }
        
        alertController.addAction(destructiveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func defaultAlert(alertTitle: String, actionTitle: String, cancelTitle: String = "Cancel", completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        
        let destructiveAction = UIAlertAction(title: actionTitle, style: .default) { _ in
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { (_) in
            completion(false)
        }
        
        alertController.addAction(destructiveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func alert(alertTitle: String? = nil, alertMessage: String? = nil, actionTitle: String? = nil, actionStyle: UIAlertAction.Style? = .default, cancelTitle: String = "Cancel", completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
        
        let destructiveAction = UIAlertAction(title: actionTitle, style: actionStyle ?? .default) { _ in
            completion(true)
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { (_) in
            completion(false)
        }
        
        alertController.addAction(destructiveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func actionSheet(alertTitle: String? = nil, alertMessage: String? = nil, actions: [UIAlertAction], completion: @escaping (UserDestructionType) -> Void) {
        let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .actionSheet)
        
        actions.forEach({ alertController.addAction($0) })
        
        present(alertController, animated: true, completion: nil)
    }
    
    func verifyLogoutActionSheet(completion: @escaping (_ logout: Bool, _ verify: Bool) -> Void) {
        let alertController = UIAlertController(title: "Email Not Verified", message: "Quickly verify your email so if you forget your password while logged out, you can reset it.", preferredStyle: .actionSheet)
        
        let verifyAction = UIAlertAction(title: "Verify Email", style: .default) { (_) in
            completion(false, true)
        }
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { (_) in
            completion(true, false)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false, false)
        }
        
        alertController.addAction(verifyAction)
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func resendMessageAlert(completion: @escaping (_ resend: Bool, _ delete: Bool) -> Void) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let resendAction = UIAlertAction(title: "Retry", style: .default) { (_) in
            completion(true, false)
        }
        
        let deleteAction = UIAlertAction(title: "Delete Message", style: .destructive) { (_) in
            completion(false, true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(false, false)
        }
        
        alertController.addAction(resendAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
