//
//  AddFriendCell.swift
//  picture
//
//  Created by Jason Goodney on 12/24/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SDWebImage

protocol AddFriendDelegate: class {
    func didTapAddFriendButton(cell: AddFriendCell, user: User, state: AddFriendState)
}

class AddFriendCell: UITableViewCell, ReuseIdentifiable {
    
    weak var delegate: AddFriendDelegate?
    private var user: User?
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    private let profileImageView = ProfileImageButton(height: 44, width: 44, enabled: false)
    
    private lazy var addFriendButton = AddFriendButton(title: "+ Add", addFriendState: .add)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with user: User) {
        self.user = user
        
        usernameLabel.text = user.username
        if let url = URL(string: user.profilePhotoUrl) {
            profileImageView.sd_setImage(with: url, for: .normal)
        }
    }
    
    func updateView(forAddFriendState state: AddFriendState) {
        
        switch state {
        case .add:
            addFriendButton.setTitle("+ Add", for: .normal)
        case .added:
            addFriendButton.setTitle("Added", for: .normal)
        case .requested:
            addFriendButton.setTitle("+ Accept", for: .normal)
        case .accepted:
            addFriendButton.setTitle("Friends", for: .normal)
        }
        
        addFriendButton.addFriendState = state
    }
    
    @objc private func handleAddFriend(_ sender: AddFriendButton) {
        guard let user = user else { return }
        delegate?.didTapAddFriendButton(cell: self, user: user, state: sender.addFriendState)
    }
}

// MARK: - UI
private extension AddFriendCell {
    func setupLayout() {
        selectionStyle = .none
        
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.distribution = .equalSpacing
        
        addSubviews(profileImageView, usernameLabel, addFriendButton)
        
        profileImageView.anchorCenterYToSuperview()
        usernameLabel.anchorCenterYToSuperview()
        addFriendButton.anchorCenterYToSuperview()
        
        profileImageView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        
        usernameLabel.anchor(top: nil, leading: profileImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        addFriendButton.anchor(top: nil, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16))
        
        updateView(forAddFriendState: .add)
        
        addFriendButton.addTarget(self, action: #selector(handleAddFriend), for: .touchUpInside)
    }
}
