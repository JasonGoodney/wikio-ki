//
//  FriendsListCell.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SDWebImage

protocol FriendsListCellDelegate: class {
    func didTapCameraButton(_ sender: PopButton)
}

class FriendsListCell: UITableViewCell, ReuseIdentifiable {
    
    weak var delegate: FriendsListCellDelegate?
    
//    var friend: User?
//    var chat: Chat?
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()
    
    private let statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return imageView
    }()
    
    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.textColor = WKTheme.textColor
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = ""
        return label
    }()
    
    private lazy var cameraButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-camera-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = WKTheme.textColor
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.contentHorizontalAlignment = .trailing
        button.addTarget(self, action: #selector(handleCameraButton), for: .touchUpInside)
        return button
    }()
    
    private let unreadView = UnreadView()
    private let statusIndicatorView = StatusIndicatorView(subviewSize: 15)

    let profileImageView = ProfileImageButton(height: 44, width: 44, enabled: false)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with name: String) {
        usernameLabel.text = name
    }
    
    func configure(with chatWithFriend: ChatWithFriend) {
        let user = chatWithFriend.friend
        let chat = chatWithFriend.chat
        
        usernameLabel.text = user.username
        if let url = URL(string: user.profilePhotoUrl) {
            profileImageView.sd_setImage(with: url, for: .normal)
        }
        
        let timeAgoString = " · \(Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).timeAgoDisplay())"
        
        if chat.isSending && chat.lastSenderUid == UserController.shared.currentUser?.uid {
            detailsLabel.text = "Sending..."
            cameraButton.tintColor = WKTheme.textColor
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: 14)
            statusIndicatorView.configure(forStatus: .sending, isOpened: false, type: .none)
        }
        else if chat.isNewFriendship && !Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).isWithinThePastWeek() {
            detailsLabel.text = "Tap to chat" + timeAgoString
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: 14)
            statusIndicatorView.configure(forStatus: .none, isOpened: false, type: .none)
            
        } else if chat.isNewFriendship {
            usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
            detailsLabel.font = UIFont.boldSystemFont(ofSize: 14)
            detailsLabel.text = "New friend" + timeAgoString
            cameraButton.tintColor = WKTheme.textColor
            statusIndicatorView.configure(forStatus: .none, isOpened: false, type: .none, isNewFriendship: true)
            
        } else if !chat.isOpened {
            if UserController.shared.currentUser!.uid == chat.lastSenderUid {
                detailsLabel.text = "Delivered" + timeAgoString
                cameraButton.tintColor = WKTheme.textColor
                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                detailsLabel.font = UIFont.systemFont(ofSize: 14)
                statusIndicatorView.configure(forStatus: .delivered, isOpened: false, type: .none)
                
            } else {
                usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
                detailsLabel.font = UIFont.boldSystemFont(ofSize: 14)
                detailsLabel.text = "New message" + timeAgoString
                cameraButton.tintColor = .black
                statusImageView.image = #imageLiteral(resourceName: "icons8-filled_circle")
                statusIndicatorView.configure(forStatus: .received, isOpened: false, type: .none)
                
            }
        } else {
            let isSender = chat.lastSenderUid == UserController.shared.currentUser?.uid
            detailsLabel.text = "Opened" + timeAgoString
            cameraButton.tintColor = WKTheme.textColor
            statusImageView.image = #imageLiteral(resourceName: "icons8-circled")
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: 14)
            statusIndicatorView.configure(forStatus: isSender ? .delivered : .received, isOpened: true, type: .none)
        }
            
            if let unread = chat.unread, let uid = UserController.shared.currentUser?.uid {
                let unreadCount = unread[uid]
                unreadView.unreadCount = unreadCount ?? 0
            }
//        }
    }
    
    @objc private func handleCameraButton() {
        delegate?.didTapCameraButton(cameraButton)
    }
}

// MARK: - UI
private extension FriendsListCell {
    func updateView() {
        backgroundColor = .white
        
        statusIndicatorView.configure(forStatus: .delivered, isOpened: false, type: .photo)
        
        let detailsStackView = UIStackView(arrangedSubviews: [statusIndicatorView, detailsLabel])
        detailsStackView.spacing = 8
        detailsStackView.heightAnchor.constraint(equalToConstant: 15).isActive = true
        
        let textStackView = UIStackView(arrangedSubviews: [usernameLabel, detailsStackView])
        textStackView.axis = .vertical
        textStackView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let overallStackView = UIStackView(arrangedSubviews: [profileImageView, textStackView, cameraButton])
        overallStackView.distribution = .fillProportionally
        overallStackView.spacing = 16
        
        addSubviews([overallStackView, unreadView])
        
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        overallStackView.anchorCenterYToSuperview()
        overallStackView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 16))
        
        
        unreadView.anchor(top: profileImageView.topAnchor, leading: profileImageView.leadingAnchor, bottom: profileImageView.bottomAnchor, trailing: profileImageView.trailingAnchor, padding: .init(top: -6, left: 0, bottom: 0, right: -6))
        
        bringSubviewToFront(unreadView)
    }
}
