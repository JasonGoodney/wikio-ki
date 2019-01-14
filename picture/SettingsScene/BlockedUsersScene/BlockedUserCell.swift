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
        button.setImage(#imageLiteral(resourceName: "close").withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(unblockButtonTapped), for: .touchUpInside)
        button.tintColor = WKTheme.darkGray
        return button
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
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
    }
    
    private func setupLayout() {
        selectionStyle = .none
        
        let stackView = UIStackView(arrangedSubviews: [usernameLabel, unblockButton])
        stackView.distribution = .equalSpacing
        addSubview(stackView)
        stackView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 8))
        
        unblockButton.widthAnchor.constraint(equalToConstant: 32).isActive = true
    }
    
    @objc private func unblockButtonTapped() {
        delegate?.handleUnblockUser(sender: unblockButton)
    }
}