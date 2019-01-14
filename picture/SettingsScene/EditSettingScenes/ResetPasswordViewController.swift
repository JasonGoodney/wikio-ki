//
//  ResetPasswordViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/11/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ResetPasswordViewController: EditSettingViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

     
        delegate = self
        
        settingTextField.delegate = self
        settingTextField.keyboardType = .emailAddress
    }
}

extension ResetPasswordViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveButton.isEnabled = textField.text == UserController.shared.currentUser!.email
    }
}

extension ResetPasswordViewController: EditSettingDelegate {
    func settingTextFieldDidChange(_ textField: UITextField, text: String) {
        
    }
    
    func updateChanges() {
        guard let email = settingTextField.text else { return }
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Sending email"
        hud.show(in: self.view)
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if let error = error {
                print(error)
                return
            }
            hud.textLabel.text = nil
            hud.indicatorView = JGProgressHUDSuccessIndicatorView()
            hud.dismiss(afterDelay: 3)
        }
    }

}
