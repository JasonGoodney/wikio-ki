//
//  RegisterViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/16/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import JGProgressHUD
import Photos
import AVKit

public struct RegisterError: Error {
    let msg: String
    
}

extension RegisterError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(msg, comment: "")
    }
}

public enum RegistrationResult<Value> {
    case success(Value)
    case failure(RegisterError)
    
    public var value: Value? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
}

class RegisterViewController: UIViewController, LoginFlowHandler {
    
    let registerViewModel = RegisterViewModel()
    let registeringHUD = JGProgressHUD(style: .dark)
    let gradientLayer = CAGradientLayer()
    
    var agreedToAgreements = false {
        didSet {
            registerViewModel.agreedToAgreements = agreedToAgreements
            if agreedToAgreements {
                agreeButton.setImage(#imageLiteral(resourceName: "icons8-ok").withRenderingMode(.alwaysTemplate), for: .normal)
                agreeButton.tintColor = Theme.buttonBlue
            } else {
                agreeButton.setImage(#imageLiteral(resourceName: "icons8-circled").withRenderingMode(.alwaysTemplate), for: .normal)
                agreeButton.tintColor = Theme.textColor
            }
        }
    }
    
    private let titleLabel = NavigationTitleLabel(title: "Create Account")
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 0.9679008152)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var selectPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-plus_math").withRenderingMode(.alwaysTemplate), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .heavy)
        button.backgroundColor = .white
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(handleSelectPhoto), for: .touchUpInside)
        button.imageView?.contentMode = .scaleAspectFill
        button.clipsToBounds = true
        button.layer.borderWidth = 1
        button.layer.borderColor = Theme.gainsboro.cgColor
        button.tintColor = Theme.gainsboro
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
        textField.placeholder = "Username"
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }()
    
    private lazy var emailTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.autocapitalizationType = .none
        textField.delegate = self
        return textField
    }()
    
    private lazy var passwordTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.placeholder = "Password"
        textField.isSecureTextEntry = true
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        textField.delegate = self
        textField.autocapitalizationType = .none
        return textField
    }()
    
    private let goToLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleGoToLogin), for: .touchUpInside)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            usernameTextField, emailTextField,
            passwordTextField, registerButton, errorLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()
    
    private let agreeButton = PopButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let touchId = TouchIDAuth()
//        touchId.authenticateUserUsingTouchID()
        
        agreedToAgreements = false
        
        setupLayout()
        setupTapGesture()

        setupNotificationObservers()
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI
    private lazy var agreementTextView: UITextView = {
        let textView = UITextView()
        textView.textAlignment = .center
        textView.isEditable = false
        textView.showsVerticalScrollIndicator = false
        textView.delegate = self
        textView.textContainerInset.top = 0
        return textView
    }()
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
        
        let attributedText = NSMutableAttributedString(string: "Have an account already?  ", attributes: [.foregroundColor: Theme.textColor])
        attributedText.append(NSAttributedString(string: "Log in", attributes: [.foregroundColor: Theme.buttonBlue]))
        
        goToLoginButton.setAttributedTitle(attributedText, for: .normal)
        
        let agreementView = UIView()
        agreementView.addSubviews([agreeButton, agreementTextView])
        
        agreeButton.anchor(top: agreementView.topAnchor, leading: agreementView.leadingAnchor, bottom: nil, trailing: nil, padding: .init(), size: .init(width: 24, height: 24))
        agreeButton.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        agreeButton.tintColor = Theme.textColor
        
        agreementTextView.anchor(top: agreeButton.topAnchor, leading: agreeButton.trailingAnchor, bottom: agreementView.bottomAnchor, trailing: agreementView.trailingAnchor, padding: .init(top: 0, left: 8, bottom: 0, right: 0))
        
        
        agreementTextView.attributedText = setupAgreementText()
        view.addSubview(agreementView)
        agreementView.anchor(top: nil, leading: stackView.leadingAnchor, bottom: goToLoginButton.topAnchor, trailing: stackView.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 16, right: 0), size: .init(width: 0, height: 70))
        
    }
    
    @objc private func agreeButtonTapped() {
        agreedToAgreements = !agreedToAgreements
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
        hud.dismiss(afterDelay: 3) {
            hud.textLabel.text = nil
        }
    }

    private func validateUsername(str: String) -> Bool {
        do
        {
            let regex = try NSRegularExpression(pattern: "^[0-9a-zA-Z\\_]{3,15}$", options: .caseInsensitive)
            if regex.matches(in: str, options: [], range: NSMakeRange(0, str.count)).count > 0 {return true}
        }
        catch {}
        
        return false
    }
    
    private func validatePassword(str: String) -> Bool {
        return str.count >= 6
    }
    
    private func setupRegisterViewModelObserver() {
        registerViewModel.bindableIsFormValid.bind { [unowned self] isFormValid in
            guard let isFormValid = isFormValid else { return }
            
            self.registerButton.isEnabled = isFormValid
            
            if isFormValid {
                self.registerButton.backgroundColor = Theme.buttonBlue
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
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            } else {
                if self.registeringHUD.isVisible {
                    self.registeringHUD.dismiss()
                }
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
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
    
    private func setupAgreementText() -> NSAttributedString {
        let regularText = attributedText("I agree to the ")

        regularText.append(tappableText("Privacy Policy"))
        regularText.append(attributedText(", "))
        regularText.append(tappableText("Terms & Conditions"))
        regularText.append(attributedText(", and "))
        regularText.append(tappableText("License Agreement"))
        regularText.append(attributedText("."))
        
        return regularText
    }
    
    private func attributedText(_ text: String) -> NSMutableAttributedString {
        let regularText = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: Theme.textColor])
        
        return regularText
    }
    
    private func tappableText(_ text: String) -> NSMutableAttributedString {
        let tappableText = NSMutableAttributedString(string: text)
        tappableText.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 14), range: NSMakeRange(0, tappableText.length))
        tappableText.addAttribute(NSAttributedString.Key.foregroundColor, value: Theme.buttonBlue, range: NSMakeRange(0, tappableText.length))
        
        tappableText.addAttribute(NSAttributedString.Key.link, value: "makeMeTappable", range: NSMakeRange(0, tappableText.length))
        
        return tappableText
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
        errorLabel.text = ""
        
//        NotificationCenter.default.addObserver(self, selector: #selector(didAgree), name: NSNotification.Name.agreeToEULA, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(didDisagree), name: NSNotification.Name.disagreeWithEULA, object: nil)
//
//        let eulaVC = UINavigationController(rootViewController: EULAViewController(type: .eula))
//        eulaVC.delegate = self
//
//        present(eulaVC, animated: true, completion: nil)
        
        if agreedToAgreements {
            didAgree()
        }
    }
    
    @objc private func handleSelectPhoto() {
        handleTapDismiss()
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallery()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        presentAlert(alert)
    }
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = true
            checkPermission(imagePicker: imagePicker)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            presentAlert(alert)
        }
    }
    
    private func openGallery() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.allowsEditing = true
            imagePicker.sourceType = .photoLibrary
            checkPermission(imagePicker: imagePicker)
        }
        else
        {
            let alert  = UIAlertController(title: "Warning", message: "You don't have permission to access gallery.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            presentAlert(alert)
        }
    }
    
    func checkPermission(imagePicker: UIImagePickerController) {
        if imagePicker.sourceType == .camera {
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            
            switch authStatus {
            case .authorized:
                present(imagePicker, animated: true, completion: nil)
            case .denied:
                self.promptToAppSettings(title: "Enable Access to Camera", message: NSLocalizedString("Wikio Ki doesn't have permission to use your camera, please change privacy settings.", comment: "Alert message when the user has denied access to the photo libary"))
            default:
                // Not determined fill fall here - after first use, when is't neither authorized, nor denied
                // we try to use camera, because system will ask itself for camera permissions
                AVCaptureDevice.requestAccess(for: .video) { (granted) in
                    if granted {
                        self.present(imagePicker, animated: true, completion: nil)
                    }
                }
            }
            
        } else if imagePicker.sourceType == .photoLibrary {
            let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
            switch photoAuthorizationStatus {
            case .authorized:
                present(imagePicker, animated: true, completion: nil)
                print("Access is granted by user")
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization({
                    (newStatus) in
                    print("status is \(newStatus)")
                    if newStatus ==  PHAuthorizationStatus.authorized {
                        /* do stuff here */
                        self.present(imagePicker, animated: true, completion: nil)
                        print("success")
                    }
                })
                print("It is not determined until now")
            case .restricted:
                // same same
                print("User do not have access to photo album.")
            case .denied:
                // same same
                print("User has denied the permission.")
                
                self.promptToAppSettings(title: "Enable Access to Photos", message: NSLocalizedString("Wikio Ki doesn't have permission to save to your Photos, please change privacy settings.", comment: "Alert message when the user has denied access to the photo libary"))
            }
        }
    }
    
    @objc func handleTapDismiss() {
        view.endEditing(true)
    }
    
    @objc func handleKeyboardShow(notification: Notification) {
        guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardFrame = value.cgRectValue
        let bottomSpace = view.frame.height - stackView.frame.origin.y - stackView.frame.height - 36
        let difference = keyboardFrame.height - bottomSpace
        view.transform = CGAffineTransform(translationX: 0, y: -difference)
        
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
        let image = info[.editedImage] ?? info[.originalImage]
        guard let selectedImage = image as? UIImage else { return }
        registerViewModel.bindableImage.value = selectedImage
        registerViewModel.profilePhoto = selectedImage
        self.selectPhotoButton.layer.borderWidth = 0
        dismiss(animated: true)
    }
}

extension RegisterViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == usernameTextField, errorLabel.text != "" {
            self.errorLabel.text = ""
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == usernameTextField {
            
            if let username = textField.text, username.isEmpty == false {
                AuthValidation.isValidUsername(username) { (registerError) in
                    if let error = registerError {
                        self.errorLabel.text = error.errorDescription
                    } else {
                        
                        self.errorLabel.text = ""
                    }
                    
                }
            }
        } else if textField == passwordTextField {
                 if let password = passwordTextField.text, password.isEmpty == false
                {
                if !validatePassword(str: password) {
                    errorLabel.text = "Password must be at least 6 characters"
                }
            }
        }
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == usernameTextField && textField.isFirstResponder {
            let validString = CharacterSet(charactersIn: " !@#$€%^&*()-_+{}[]|\"<>,.~`/:;?=\\¥'£•¢")
            
            if (textField.textInputMode?.primaryLanguage == "emoji") || textField.textInputMode?.primaryLanguage == nil {
                return false
            }
            if let _ = string.rangeOfCharacter(from: validString) {
                return false
            }
        } else if textField.isFirstResponder {
            if (textField.textInputMode?.primaryLanguage == "emoji") || textField.textInputMode?.primaryLanguage == nil {
                return false
            }
        }
        
        return true
    }

}

extension RegisterViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {

        if URL.absoluteString == "makeMeTappable"{
            
            var aboutVC: AboutViewController!
            let startIndex = textView.text.index(textView.text.startIndex, offsetBy: characterRange.location)
            let endIndex = textView.text.index(textView.text.startIndex, offsetBy: characterRange.upperBound)
            let tappedText = textView.text[startIndex..<endIndex]
            
            if tappedText == "Privacy Policy" {
                aboutVC = AboutViewController(type: .privacyPolicy)
            } else if tappedText == "Terms & Conditions" {
                aboutVC = AboutViewController(type: .termsAndConditions)
            } else if tappedText == "License Agreement" {
                aboutVC = AboutViewController(type: .eula)
            }
            
            navigationController?.pushViewController(aboutVC, animated: true)
            
            return false // return false for this to work
        }
        
        return true
    }
}

extension RegisterViewController: AgreementDelegate {
    @objc func didAgree() {
        registerViewModel.performRegistration { [unowned self] (error) in
            if let error = error {
                self.showHUDWithError(error)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            print("🤪Finised registering the user")
            print("🤪Logged in successfully")
            let window = UIApplication.shared.keyWindow
            self.handleLogin(withWindow: window, completion: { (user) in
                if let _ = user {
                }
            })
        }
    }
    
    @objc func didDisagree() {
        print("Disagreed or cancel button tapped")
        setupRegisterViewModelObserver()
    }
}
