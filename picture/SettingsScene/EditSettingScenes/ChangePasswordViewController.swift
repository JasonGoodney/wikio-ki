//
//  ChangePasswordViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/10/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ChangePasswordViewController: EditSettingViewController {
    
    private let newPasswordTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.isSecureTextEntry = true
        textField.placeholder = "New password"
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }()
    
    private let confirmPasswordTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.isSecureTextEntry = true
        textField.placeholder = "Confirm password"
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return textField
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 0.9679008152)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var updatePasswordStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [newPasswordTextField, confirmPasswordTextField, errorLabel])
        stackView.spacing = 8
        stackView.axis = .vertical
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(updatePasswordStackView)
        
        updatePasswordStackView.anchor(top: settingTextField.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 16, bottom: 0, right: 16))
        updatePasswordStackView.heightAnchor.constraint(equalToConstant: 108+24).isActive = true
        
        settingTextField.isSecureTextEntry = true
        
        settingTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        delegate = self
    }
    
    func isValidUpdatedPassword() -> Bool {
        guard let current = settingTextField.text, !current.isEmpty,
            let new = newPasswordTextField.text, !new.isEmpty,
            let confirm = confirmPasswordTextField.text, !confirm.isEmpty else { return false }
        
//        let isValid = current != new && new == confirm
        return true
    }

}

extension ChangePasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorLabel.text = ""
        saveButton.isEnabled = isValidUpdatedPassword()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        saveButton.isEnabled = isValidUpdatedPassword()
    }
}

extension ChangePasswordViewController: EditSettingDelegate {
    func settingTextFieldDidChange(_ textField: UITextField, text: String) {
        
    }
    
    func updateChanges() {
        guard let current = settingTextField.text,
            let new = newPasswordTextField.text,
            let confirm = confirmPasswordTextField.text else { return }
        
        if current == new || current == confirm {
            errorLabel.text = "New password cannot be the same as the current."
            
        } else if new != confirm {
            errorLabel.text = "Passwords do not match."
            
        } else {
            let hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Updating Password"
            hud.show(in: self.view)
            
            Auth.auth().currentUser?.updatePassword(to: new, completion: { (error) in
                if let error = error {
                    print(error)
                    if error._code == 17014 {
                        hud.dismiss()
                        self.reauthenticateAlert(message: error.localizedDescription) { (email, password)  in
                            guard let email = email, let password = password else { return }
                            
                            let credential: AuthCredential = EmailAuthProvider.credential(withEmail: email, password: password)
                            
                            Auth.auth().currentUser?.reauthenticateAndRetrieveData(with: credential, completion: { (user, error) in
                                if let error = error {
                                    print(error)
                                    return
                                }
                                
                                print("Re authed user")
                            })
                            
                        }
                    }
                    return
                }
                
                self.navigationController?.popViewController(animated: true)
                print("Updated password")
            })
        }
    }
}
