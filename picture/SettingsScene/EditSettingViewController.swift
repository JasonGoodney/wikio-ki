//
//  EditSettingViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class EditSettingViewController: UIViewController {

    private let navTitle: String
    private let message: String
    private let text: String
    private let placeholder: String
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private let settingTextField: UITextField = {
        let textField = UITextField()
        return textField
    }()
    
    init(title: String, message: String, text: String, placeholder: String) {
        self.navTitle = title
        self.message = message
        self.text = text
        self.placeholder = placeholder
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: navTitle)
        messageLabel.text = message
        settingTextField.text = text
        settingTextField.placeholder = placeholder
        
        setupView()
    }
    
    private func setupView() {
        view.addSubviews(messageLabel, settingTextField)
        
        messageLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 64, bottom: 0, right: 64))
        
        settingTextField.anchor(top: messageLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 0, bottom: 0, right: 0))
    }
}
