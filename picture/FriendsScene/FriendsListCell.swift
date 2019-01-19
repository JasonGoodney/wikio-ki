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
    
    var friend: User?
    var chat: Chat?
    
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

    let profileImageView = ProfileImageButton(height: 44, width: 44, enabled: true)
    
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
    
    func configure(with user: User) {
        self.friend = user
        
        usernameLabel.text = user.username
        if let url = URL(string: user.profilePhotoUrl) {
            profileImageView.sd_setImage(with: url, for: .normal)
        }
        
        let dbs = DatabaseService()
        
        dbs.fetchChat(withFriend: user) { (chat, error) in
            if let error = error {
                print(error)
                return
            }
            
            guard let chat = chat else { return }
            self.chat = chat
            
            let timeAgoString = " · \(Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).timeAgoDisplay()) · \(Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).testingTimestamp())"
            
            if chat.isNewFriendship && !Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).isWithinThePastWeek() {
                self.detailsLabel.text = "Tap to chat" + timeAgoString
                self.usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                self.detailsLabel.font = UIFont.systemFont(ofSize: 14)
            } else if chat.isNewFriendship {
                self.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
                self.detailsLabel.font = UIFont.boldSystemFont(ofSize: 14)
                self.detailsLabel.text = "New Friend" + timeAgoString
                self.cameraButton.tintColor = WKTheme.textColor
            } else if !chat.isOpened {
                if UserController.shared.currentUser!.uid == chat.lastSenderUid {
                    self.detailsLabel.text = "Delivered" + timeAgoString
                    self.cameraButton.tintColor = WKTheme.textColor
                    self.usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                    self.detailsLabel.font = UIFont.systemFont(ofSize: 14)
                } else {
                    self.usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
                    self.detailsLabel.font = UIFont.boldSystemFont(ofSize: 14)
                    self.detailsLabel.text = "New Message" + timeAgoString
                    self.cameraButton.tintColor = .black
                    self.statusImageView.image = #imageLiteral(resourceName: "icons8-filled_circle")
                    
                }
            } else {
                self.detailsLabel.text = "Opened" + timeAgoString
                self.cameraButton.tintColor = WKTheme.textColor
                self.statusImageView.image = #imageLiteral(resourceName: "icons8-circled")
                self.usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                self.detailsLabel.font = UIFont.systemFont(ofSize: 14)
            }
        }
    }
    
    @objc private func handleCameraButton() {
        delegate?.didTapCameraButton(cameraButton)
    }
}

// MARK: - UI
private extension FriendsListCell {
    func updateView() {
        backgroundColor = .white
        
        let textStackView = UIStackView(arrangedSubviews: [usernameLabel, detailsLabel])
        textStackView.axis = .vertical
        textStackView.backgroundColor = .orange
        textStackView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        let overallStackView = UIStackView(arrangedSubviews: [profileImageView, textStackView, cameraButton])
        overallStackView.distribution = .fillProportionally
        overallStackView.spacing = 16
        
        addSubviews(overallStackView)
        
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        overallStackView.anchorCenterYToSuperview()
        overallStackView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 16))

    }
}
