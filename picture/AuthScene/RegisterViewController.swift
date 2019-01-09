//
//  RegisterViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/16/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD

public struct RegisterError: Error {
    let msg: String
    
}

extension RegisterError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(msg, comment: "")
    }
}

class RegisterViewController: UIViewController, LoginFlowHandler {
    
    let registerViewModel = RegisterViewModel()
    let registeringHUD = JGProgressHUD(style: .dark)
    let gradientLayer = CAGradientLayer()
    
    private let titleLabel = NavigationTitleLabel(title: "Create Account")
    private lazy var selectPhotoButton: UIButton = {
        let button = UIButton(type: .system)
//        button.setTitle("Select Photo", for: .normal)
        button.setImage(#imageLiteral(resourceName: "icons8-plus_math"), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleSelectPhoto), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFill
        button.clipsToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = WKTheme.gainsboro.cgColor
        return button
    }()
    
    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Register", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .lightGray
        button.setTitleColor(.gray, for: .normal)
        button.isEnabled = false
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)
        return button
    }()
    
    private lazy var usernameTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Enter username"
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private let emailTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Enter email"
        textField.keyboardType = .emailAddress
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let passwordTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Enter password"
        textField.isSecureTextEntry = true
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        return textField
    }()
    
    private let goToLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleGoToLogin), for: .touchUpInside)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            usernameTextField, emailTextField,
            passwordTextField, registerButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //setupGradientLayer()
        setupLayout()
        setupNotificationObservers()
        setupTapGesture()
        setupRegisterViewModelObserver()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.titleView = titleLabel
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI
    private func setupLayout() {
        view.backgroundColor = .white
        view.addSubviews(selectPhotoButton, stackView, goToLoginButton)
        
        stackView.anchorCenterYToSuperview(constant: 64)
        stackView.anchor(top: nil, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 50, bottom: 0, right: 50))
        
        selectPhotoButton.anchorCenterXToSuperview()
        let buttonSide: CGFloat = 128
        selectPhotoButton.anchor(top: nil, leading: nil, bottom: stackView.topAnchor, trailing: nil, padding: .init(top: 0, left: 0, bottom: 24, right: 0), size: .init(width: buttonSide, height: buttonSide))
        
        selectPhotoButton.layer.cornerRadius = buttonSide / 2
        
        goToLoginButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        let attributedText = NSMutableAttributedString(string: "Have an account already? ", attributes: [.foregroundColor: UIColor.lightGray])
        attributedText.append(NSAttributedString(string: "Log in", attributes: [.foregroundColor: #colorLiteral(red: 0, green: 0.5694751143, blue: 1, alpha: 1)]))
        
        goToLoginButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        selectPhotoButton.layer.cornerRadius = 64
    }
    
    private func showHUDWithError(_ error: Error) {
        registeringHUD.dismiss()
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Registration Failed"
        hud.detailTextLabel.text = error.localizedDescription
        hud.show(in: view)
        hud.dismiss(afterDelay: 3)
    }

    private func validateUsername(str: String) -> Bool
    {
        do
        {
            let regex = try NSRegularExpression(pattern: "^[0-9a-zA-Z\\_]{3,15}$", options: .caseInsensitive)
            if regex.matches(in: str, options: [], range: NSMakeRange(0, str.count)).count > 0 {return true}
        }
        catch {}
        
        return false
    }
    
    private func setupRegisterViewModelObserver() {
        registerViewModel.bindableIsFormValid.bind { [unowned self] isFormValid in
            guard let isFormValid = isFormValid else { return }
            self.registerButton.isEnabled = isFormValid
            if isFormValid {
                self.registerButton.backgroundColor = #colorLiteral(red: 0.7865832448, green: 0.09652689844, blue: 0.2869956195, alpha: 1)
                self.registerButton.setTitleColor(.white, for: .normal)
            } else {
                self.registerButton.backgroundColor = .lightGray
                self.registerButton.setTitleColor(.gray, for: .normal)
            }
        }
        
        registerViewModel.bindableImage.bind { [unowned self] image in
            self.selectPhotoButton.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        
        registerViewModel.bindableIsRegistering.bind { [unowned self] isRegistering in
            if isRegistering == true {
                self.registeringHUD.textLabel.text = "Registering"
                self.registeringHUD.show(in: self.view)
            } else {
                self.registeringHUD.dismiss()
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func setupGradientLayer() {
        let topColor = #colorLiteral(red: 0.9494370818, green: 0.3069118261, blue: 0.3441247344, alpha: 1).cgColor
        let bottomColor = #colorLiteral(red: 0.878726542, green: 0.1067085937, blue: 0.3991346955, alpha: 1).cgColor
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0, 1]
        view.layer.addSublayer(gradientLayer)
        gradientLayer.frame = view.bounds
    }
}

// MARK: - Actions
private extension RegisterViewController {
    @objc func handleGoToLogin() {
        let loginVC = LoginController()
        navigationController?.pushViewController(loginVC, animated: true)
    }
    
    @objc func handleTextChanged(textField: UITextField) {
        if textField == usernameTextField {
            registerViewModel.username = textField.text
        } else if textField == emailTextField {
            registerViewModel.email = textField.text
        } else {
            registerViewModel.password = textField.text
        }
    }
    
    @objc func handleRegister() {
        handleTapDismiss()
        
        registerViewModel.performRegistration { [unowned self] (error) in
            if let error = error {
                self.showHUDWithError(error)
                return
            }
            print("Finised registering the user")
            print("Logged in successfully")
            let window = UIApplication.shared.keyWindow
            self.handleLogin(withWindow: window, completion: { (user) in
                if let _ = user {
                    UserController.shared.fetchCurrentUser()
                }
            })
        }
    }
    
    @objc func handleSelectPhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    @objc func handleTapDismiss() {
        view.endEditing(true)
    }
    
    @objc func handleKeyboardShow(notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = value.cgRectValue
        let bottomSpace = view.frame.height - stackView.frame.origin.y - stackView.frame.height
        let difference = keyboardFrame.height - bottomSpace
        view.transform = CGAffineTransform(translationX: 0, y: -difference - 8)
    }
    
    @objc func handleKeyboardHide() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.view.transform = .identity
        })
    }
    
    func setupTapGesture() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
    }
}

// MARK: - UIImagePickerControllerDelegate
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        registerViewModel.bindableImage.value = selectedImage
        registerViewModel.profilePhoto = selectedImage
        dismiss(animated: true) {
            self.selectPhotoButton.layer.borderWidth = 0
        }
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == usernameTextField {
            if let username = textField.text, username.isEmpty == false {
                if !validateUsername(str: username) {
                    let error = RegisterError(msg: "Invalid Username")
                    showHUDWithError(error)
                }
            }
        }
    }
}
