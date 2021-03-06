//
//  LoginController.swift
//  SwipeMatchFirestoreLBTA
//
//  Created by Brian Voong on 11/26/18.
//  Copyright © 2018 Brian Voong. All rights reserved.
//

import UIKit
import JGProgressHUD
import FirebaseInstanceID
import FirebaseAuth
import FirebaseMessaging

protocol LoginControllerDelegate {
    func didFinishLoggingIn()
}

class LoginController: UIViewController, LoginFlowHandler {
    
    var delegate: LoginControllerDelegate?
    
    private let titleLabel = NavigationTitleLabel(title: "Log in to \(Bundle.appName())")
    
    private let emailTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        
        return textField
    }()
    
    private let passwordTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.autocapitalizationType = .none
        return textField
    }()
    
    lazy var verticalStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [
            emailTextField,
            passwordTextField,
            loginButton
            ])
        sv.axis = .vertical
        sv.spacing = 8
        return sv
    }()
    
    @objc fileprivate func handleTextChanged(textField: UITextField) {
        if textField == emailTextField {
            loginViewModel.email = textField.text?.trimmingCharacters(in: .whitespaces)
        } else {
            loginViewModel.password = textField.text
        }
    }
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        button.backgroundColor = .lightGray
        button.setTitleColor(.gray, for: .disabled)
        button.isEnabled = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    
    @objc fileprivate func handleLogin() {
        view.endEditing(true)
        
        loginViewModel.performLogin { (err) in
            
            if let err = err {
                self.loginHUD.dismiss()
                let title = err._userInfo!["error_name"] as! String
                let message = err.localizedDescription
                self.errorAlert(alertTitle: title, alertMessage: message)
                print("Failed to log in:", err)
                #warning("display error message to user")
                return
            }
            
            print("Logged in successfully")
            let window = UIApplication.shared.keyWindow
            UserController.shared.fetchCurrentUser(completion: { (fetched) in
                if fetched {
                    self.handleLogin(withWindow: window, completion: { (firebaseUser) in
                        if let _ = firebaseUser {
                            
                        }
                        self.loginHUD.dismiss()
                    })
                }
            })
        }
    }
    
    fileprivate lazy var backToRegisterButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Go back", for: .normal)
        button.setTitleColor(#colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1), for: .normal)
        button.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    fileprivate lazy var forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot password?", for: .normal)
        button.setTitleColor(Theme.textColor, for: .normal)
        button.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    @objc fileprivate func handleBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleForgotPassword() {
        print("🤶\(#function)")
        passwordResetAlert { (email) in
            guard let email = email else { return }
            
            let hud = JGProgressHUD(style: .dark)
            hud.textLabel.text = "Sending password reset email."
            hud.show(in: self.view)
            Auth.auth().sendPasswordReset(withEmail: email) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("Password reset link sent to: \(email)")
                hud.indicatorView = JGProgressHUDSuccessIndicatorView()
                hud.textLabel.text = "Email sent."
                hud.dismiss(afterDelay: 2)
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupLayout()
        setupNotificationObservers()
        setupBindables()
        setupTapGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.titleView = titleLabel
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate let loginViewModel = LoginViewModel()
    fileprivate let loginHUD = JGProgressHUD(style: .dark)
    
    fileprivate func setupBindables() {
        loginViewModel.isFormValid.bind { [unowned self] (isFormValid) in
            guard let isFormValid = isFormValid else { return }
            self.loginButton.isEnabled = isFormValid
            self.loginButton.backgroundColor = isFormValid ? Theme.buttonBlue : .lightGray
            self.loginButton.setTitleColor(isFormValid ? .white : .gray, for: .normal)
        }
        loginViewModel.isLoggingIn.bind { [unowned self] (isRegistering) in
            if isRegistering == true {
                self.loginHUD.textLabel.text = "Loading"
                self.loginHUD.show(in: self.view)
            } else {
                self.loginHUD.dismiss()
            }
        }
    }
    
    let gradientLayer = CAGradientLayer()
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    fileprivate func setupGradientLayer() {
        let topColor = #colorLiteral(red: 0.9921568627, green: 0.3568627451, blue: 0.3725490196, alpha: 1)
        let bottomColor = #colorLiteral(red: 0.8980392157, green: 0, blue: 0.4470588235, alpha: 1)
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.locations = [0, 1]
        view.layer.addSublayer(gradientLayer)
        gradientLayer.frame = view.bounds
    }
    
    fileprivate func setupLayout() {
        
        view.addSubviews([verticalStackView, forgotPasswordButton, backToRegisterButton])
        
        verticalStackView.anchor(top: nil, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 50, bottom: 0, right: 50))
        verticalStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        forgotPasswordButton.anchor(top: verticalStackView.bottomAnchor, leading: verticalStackView.leadingAnchor, bottom: nil, trailing: verticalStackView.trailingAnchor, padding: .init(top: 8, left: 0, bottom: 0, right: 0))
        
        backToRegisterButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        let attributedText = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [.foregroundColor: Theme.textColor])
        attributedText.append(NSAttributedString(string: "Create one", attributes: [.foregroundColor: #colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1)]))
        
        backToRegisterButton.setAttributedTitle(attributedText, for: .normal)
        
        
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleTapDismiss() {
        view.endEditing(true)
    }
    
    @objc func handleKeyboardShow(notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = value.cgRectValue
        let bottomSpace = view.frame.height - verticalStackView.frame.origin.y - verticalStackView.frame.height - forgotPasswordButton.frame.height
        let difference = keyboardFrame.height - bottomSpace
        view.transform = CGAffineTransform(translationX: 0, y: -difference - 16)
    }
    
    @objc func handleKeyboardHide() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.transform = .identity
        })
    }

    
    func setupTapGesture() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
    }
    
    func passwordResetAlert(completion: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: "Forgot password?", message: "Enter your email.", preferredStyle: .alert)
        
        alertController.addTextField { (tf) in
            tf.placeholder = "Email"
            tf.keyboardType = .emailAddress
        }
        
        let okAction = UIAlertAction(title: "Send", style: .default) { (_) in
            guard let email = alertController.textFields?[0].text, email != "" else { return }
            completion(email)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(nil)
        }
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        presentAlert(alertController)
    }
}
