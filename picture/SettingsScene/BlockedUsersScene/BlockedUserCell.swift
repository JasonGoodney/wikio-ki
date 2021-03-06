//
//  BlockedUserCell.swift
//  picture
//
//  Created by Jason Goodney on 1/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

protocol BlockedUserCellDelegate: class {
    func handleUnblockUser(sender: UIButton)
}

class BlockedUserCell: UITableViewCell, ReuseIdentifiable {
    
    weak var delegate: BlockedUserCellDelegate?
    
    lazy var unblockButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-multiply-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(unblockButtonTapped), for: .touchUpInside)
        button.tintColor = Theme.darkGray
        return button
    }()
    
    private let displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = Theme.ultraDarkGray
        return label
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = Theme.darkGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    func configure(withBlockedUser blockedUser: User) {
        usernameLabel.text = blockedUser.username
        displayNameLabel.text = blockedUser.displayName
    }
    
    private func setupLayout() {
        selectionStyle = .none
        
        let namesStackView = UIStackView(arrangedSubviews: [displayNameLabel, usernameLabel])
        namesStackView.axis = .vertical
        namesStackView.spacing = 4
        
        let stackView = UIStackView(arrangedSubviews: [namesStackView, unblockButton])
        stackView.distribution = .equalSpacing
        
        addSubview(stackView)
        stackView.anchorCenterYToSuperview()
        stackView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 16))
        
        unblockButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
        
        let separatorView = UIView()
        separatorView.backgroundColor = Theme.gainsboro

    }
    
    @objc private func unblockButtonTapped() {
        delegate?.handleUnblockUser(sender: unblockButton)
    }
}
