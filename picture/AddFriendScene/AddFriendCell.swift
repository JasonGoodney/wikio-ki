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
    func didTapCancelReceivedRequest(cell: AddFriendCell, user: User, state: AddFriendState)
}

class AddFriendCell: UITableViewCell, ReuseIdentifiable {
    
    weak var delegate: AddFriendDelegate?
    var addFriendState: AddFriendState = .add
    
    private var user: User?
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let profileImageView = ProfileImageButton(height: 44, width: 44, enabled: true)
    
    private lazy var addFriendButton = AddFriendButton(title: "+ Add", addFriendState: .add)
    
    private lazy var cancelReceivedRequestButton: PopButton = {
        let button = PopButton()
        button.setImage(#imageLiteral(resourceName: "icons8-multiply-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = WKTheme.textColor
        button.addTarget(self, action: #selector(cancelReceivedRequestButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

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
        
        cancelReceivedRequestButton.isHidden = state == .requested ? false : true
        
        addFriendButton.setTitle(state.rawValue, for: .normal)
        addFriendState = state

        if state == .accepted {
            addFriendButton.addFriendState = state
        }
    }
    
    @objc private func handleAddFriend(_ sender: AddFriendButton) {
        
        guard let user = user else { return }
        delegate?.didTapAddFriendButton(cell: self, user: user, state: addFriendState)
    }
    
    @objc private func cancelReceivedRequestButtonTapped(_ sender: PopButton) {
        guard let user = user else { return }
        delegate?.didTapCancelReceivedRequest(cell: self, user: user, state: .requested)
    }
}

// MARK: - UI
private extension AddFriendCell {
    func setupLayout() {
        selectionStyle = .none
        
        let stackView = UIStackView(arrangedSubviews: [addFriendButton, cancelReceivedRequestButton])
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        
        addSubviews([profileImageView, usernameLabel, stackView])
        
        profileImageView.anchorCenterYToSuperview()
        usernameLabel.anchorCenterYToSuperview()
//        addFriendButton.anchorCenterYToSuperview()
//        cancelReceivedRequestButton.anchorCenterYToSuperview()
        stackView.anchorCenterYToSuperview()
        
        profileImageView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        
        usernameLabel.anchor(top: nil, leading: profileImageView.trailingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
//        cancelReceivedRequestButton.anchor(top: nil, leading: addFriendButton.trailingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16))
//        addFriendButton.anchor(top: nil, leading: nil, bottom: nil, trailing: cancelReceivedRequestButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16))
        
        stackView.anchor(top: nil, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16))
        
        updateView(forAddFriendState: .add)
        
        addFriendButton.addTarget(self, action: #selector(handleAddFriend), for: .touchUpInside)
    }
}
