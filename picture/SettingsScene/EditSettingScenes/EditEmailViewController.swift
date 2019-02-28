//
//  EditEmailViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/9/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class EditEmailViewController: EditSettingViewController {
    
    private lazy var verifyEmailLabel: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(handleVerifyEmail), for: .touchUpInside)
        button.setTitleColor(labelTextColor, for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = labelFont
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()

        settingTextField.keyboardType = .emailAddress
        
        delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupForEmailVerification()
    }
    
    private func setupForEmailVerification() {
        if (Auth.auth().currentUser?.isEmailVerified)! {
            verifyEmailLabel.setTitle("Your email addres is verified", for: .normal)
            verifyEmailLabel.isUserInteractionEnabled = false
        } else {
            let attributedText = NSMutableAttributedString(string: "Verify your email address.  ", attributes: [.foregroundColor: labelTextColor])
            attributedText.append(NSAttributedString(string: "Tap here.", attributes: [.foregroundColor: Theme.buttonBlue]))
            verifyEmailLabel.setAttributedTitle(attributedText, for: .normal)
            verifyEmailLabel.isUserInteractionEnabled = true
        }
    }
    
    private func setupLayout() {
        view.addSubviews(verifyEmailLabel)
        
        verifyEmailLabel.anchor(top: settingTextField.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 20, bottom: 0, right: 20))
    }
    
    @objc private func handleVerifyEmail() {
        guard let email = UserController.shared.currentUser?.email else { return }
        
        sendVerifyEmailAlert(to: email) { (send) in
            if send {
                let hud = JGProgressHUD(style: .dark)
                hud.textLabel.text = "Sending"
                hud.show(in: self.view)
                print("sending email verification to \(email)")
                let auth = AuthService()
                
                auth.sendEmailVerifiction(currentUser: UserController.shared.firebaseUser!, completion: { (error) in
                    if let error = error {
                        hud.dismiss()
                        print("Error sending email: \(error)")
                        if error._code == 17014 {
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
                    hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                    hud.textLabel.text = "Sent"
                    hud.dismiss(afterDelay: 2)
                    print("Verification email sent")
                })
            }
        }
    }
    
    func isValidEmail(testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}

extension EditEmailViewController: EditSettingDelegate {
    func settingTextFieldDidChange(_ textField: UITextField, text: String) {
        if textField.text == textFieldText {
            print(textFieldText)
            saveButton.isEnabled = false
        } else if let email = textField.text, isValidEmail(testStr: email) {
            saveButton.isEnabled = true
        } else {
            saveButton.isEnabled = false
        }
    }
    
    func updateChanges() {
        guard let email = settingTextField.text, AuthValidation.isValidEmail(email) else { return }
        let hud = JGProgressHUD(style: .dark)
        
        Auth.auth().currentUser?.updateEmail(to: email, completion: { (error) in
            if let error = error {
                print(error)
                if error._code == 17014 {
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
            hud.textLabel.text = "Updating Email"
            hud.show(in: self.view)
            let dbs = DatabaseService()
            let fields = [User.Keys.email: email]
            dbs.updateUser(withFields: fields, completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                hud.dismiss()
                print("updated email for \(UserController.shared.currentUser!.username) to \(email)")
             
                UserController.shared.fetchCurrentUser(completion: { (success) in
                    if success {
                        self.navigationController?.popViewController(animated: true)
                    }
                })
            })
        })
    }
}

extension UIButton {
    func alignImageRight() {
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            semanticContentAttribute = .forceRightToLeft
        }
        else {
            semanticContentAttribute = .forceLeftToRight
        }
    }
}

