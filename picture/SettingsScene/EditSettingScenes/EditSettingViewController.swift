//
//  EditSettingViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/9/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

protocol EditSettingDelegate: class {
    func settingTextFieldDidChange(_ textField: UITextField, text: String)
    func updateChanges()
}

class EditSettingViewController: UIViewController {
    
    weak var delegate: EditSettingDelegate?
    
    let labelTextColor = Theme.textColor
    let labelFont = UIFont.systemFont(ofSize: 14, weight: .medium)
    
    let navigationTitle: String
    let descriptionText: String
    let textFieldText: String
    let textFieldPlaceholder: String
    
    private lazy var titleLabel = NavigationTitleLabel(title: self.navigationTitle)
    
    lazy var settingDescriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = labelFont
        label.textColor = labelTextColor
        return label
    }()
    
    let settingTextField: RoundRectTextField = {
        let textField = RoundRectTextField()
        textField.autocapitalizationType = .none
        textField.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        return textField
    }()
    
    lazy var saveButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleSaveChanges))
        button.isEnabled = false
        return button
    }()
    
    init(navigationTitle: String, descriptionText: String, textFieldText: String, textFieldPlaceholder: String) {
        
        self.navigationTitle = navigationTitle
        self.descriptionText = descriptionText
        self.textFieldText = textFieldText
        self.textFieldPlaceholder = textFieldPlaceholder
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        
        view.backgroundColor = .white
        
        navigationItem.titleView = titleLabel
        settingDescriptionLabel.text = descriptionText
        settingTextField.text = textFieldText
        settingTextField.placeholder = textFieldPlaceholder
        
        navigationItem.rightBarButtonItem = saveButton
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
    }
    
    private func setupLayout() {
        view.addSubviews(settingDescriptionLabel, settingTextField)
        
        settingDescriptionLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 32, bottom: 0, right: 32))
        
        settingTextField.anchor(top: settingDescriptionLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 16, bottom: 0, right: 16))
    }
    
    @objc func handleSaveChanges() {
        delegate?.updateChanges()
    }
    
    @objc func handleTextChanged(textField: UITextField) {
        delegate?.settingTextFieldDidChange(textField, text: textFieldText)
    }
    
    @objc func handleTapDismiss() {
        view.endEditing(true)
    }
}

// MARK: - reauthenticate alert
extension EditSettingViewController {
    func reauthenticateAlert(title: String? = "Reauthenticate", message: String?, completion: @escaping (_ email: String?, _ password: String?) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        let logInAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            guard let email = alertController.textFields?[0].text, !email.isEmpty,
                let password = alertController.textFields?[1].text, !password.isEmpty else {
                    completion(nil, nil)
                    return
            }
            completion(email.trimmingCharacters(in: .whitespaces), password.trimmingCharacters(in: .whitespaces))
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            completion(nil, nil)
        }
        
        alertController.addAction(logInAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
