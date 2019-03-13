//
//  EULAViewController.swift
//  picture
//
//  Created by Jason Goodney on 3/12/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

protocol AgreementDelegate: class {
    func didAgree()
}

class EULAViewController: AboutViewController, UITableViewDelegate {
    
    private lazy var agreeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        button.setTitleColor(Theme.buttonBlue, for: .normal)
        button.setTitle("I Agree", for: .normal)
        button.addTarget(self, action: #selector(agreeButtonTapped), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
    
    private lazy var disagreeButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        button.setTitleColor(Theme.buttonBlue, for: .normal)
        button.setTitle("I Disgree", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.alpha = 0
        return button
    }()
    
    private var stackView: UIStackView!
    private let footer = UIView()
    
    weak var delegate: AgreementDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.contentInset.bottom = 56
        tableView.separatorInset = .init()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLayout()
    }
    
    private func setupLayout() {
        
        footer.alpha = 0
        footer.backgroundColor = .white
        
        stackView = UIStackView(arrangedSubviews: [disagreeButton, agreeButton])
        view.addSubview(footer)
        footer.addSubview(stackView)

        
        footer.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0), size: .init(width: 0, height: 56))
        stackView.distribution = .fillEqually
        stackView.anchor(top: footer.topAnchor, leading: footer.leadingAnchor, bottom: footer.bottomAnchor, trailing: footer.trailingAnchor)
    }
    
    @objc private func agreeButtonTapped() {
        
        dismiss(animated: true) {
            NotificationCenter.default.post(name: NSNotification.Name.agreeToEULA, object: nil)
        }
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

extension EULAViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            UIView.animate(withDuration: 0.25) {
                self.footer.alpha = 1
                self.agreeButton.alpha = 1
                self.disagreeButton.alpha = 1
            }
        }
    }
}
