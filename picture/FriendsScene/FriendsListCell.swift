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

protocol Resendable: class {
    var doubleTapGesture: UITapGestureRecognizer { get set }
    func resendFailedMessage(cell: ReuseIdentifiable)
}

class FriendsListCell: UITableViewCell, ReuseIdentifiable, Resendable {
    
    var doubleTapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    @objc private func handleDoubleTapGesture() {
        resendFailedMessage(cell: self)
    }
    
    func resendFailedMessage(cell: ReuseIdentifiable) {
        
    }
    
    
    weak var delegate: FriendsListCellDelegate?
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        label.textColor = WKTheme.secondaryBackground
        return label
    }()
    
    private let statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        return imageView
    }()
    
    private let detailsTextFontSize: CGFloat = 13
    private lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.textColor = WKTheme.textColor
        label.text = ""
        label.font = UIFont.systemFont(ofSize: detailsTextFontSize)
        return label
    }()
    
    private lazy var cameraButton: PopButton = {
        let button = PopButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "icons8-camera-90").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = WKTheme.textColor
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: #selector(handleCameraButton), for: .touchUpInside)
//        button.backgroundColor = WKTheme.buttonBlue
        return button
    }()
    
    //private let unreadView = UnreadView()
    private let unreadView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        view.layer.cornerRadius = 6
        view.backgroundColor = WKTheme.buttonLightBlue
        return view
    }()
    
    private let statusIndicatorView = StatusIndicatorView(subviewSize: 15)

    let profileImageView = ProfileImageButton(height: 44, width: 44, enabled: true)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    func configure(with name: String) {
        usernameLabel.text = name
    }
    
    func attibutedText(detailsText: String, detailsTextColor: UIColor = WKTheme.textColor, timeAgoString: String, isBold: Bool = false) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(string: detailsText, attributes: [
            .font: isBold ? UIFont.systemFont(ofSize: detailsTextFontSize, weight: .bold) : UIFont.systemFont(ofSize: detailsTextFontSize),
            .foregroundColor: detailsTextColor
        ])
        attributedString.append(NSAttributedString(string: timeAgoString, attributes: [
            .font: isBold ? UIFont.boldSystemFont(ofSize: detailsTextFontSize) : UIFont.systemFont(ofSize: detailsTextFontSize),
            .foregroundColor: WKTheme.textColor
        ]))
        
        return attributedString
    }
    
    
    func configure(with chatWithFriend: ChatWithFriend) {
        
        let user = chatWithFriend.friend
        let chat = chatWithFriend.chat
        
        let type = chat.lastMessageSentType
        
        var textColor: UIColor {
            switch type {
            case .photo:
                return WKTheme.photo
            case .video:
                return WKTheme.video
            default:
                return WKTheme.textColor
            }
        }
        
//        if let unread = chat.unread, let uid = UserController.shared.currentUser?.uid {
//            let unreadCount = unread[uid]
//            unreadView.unreadCount = unreadCount ?? 0
//        }
        
        usernameLabel.text = user.username
        if let url = URL(string: user.profilePhotoUrl) {
            profileImageView.sd_setImage(with: url, for: .normal)
        }
        
        let timeAgoString = "  ·  \(Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).timeAgoDisplay())"
        
        let isLastSender = chat.lastSenderUid == UserController.shared.currentUser?.uid
        let unreads = chat.unread?[UserController.shared.currentUser!.uid] ?? false
        let hasUnreads = unreads
        
        unreadView.isHidden = !hasUnreads
        
        if isLastSender && chat.isSending {
            cameraButton.tintColor = WKTheme.textColor
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            detailsLabel.text = "Sending - Do not close 🙏"
            statusIndicatorView.configure(forStatus: .sending, isOpened: false, type: type)
            return
        }
        
        if chat.isNewFriendship && !Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).isWithinThePastWeek() {
            detailsLabel.text = "Tap to chat" + timeAgoString
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            statusIndicatorView.configure(forStatus: .none, isOpened: false, type: type)
            return
            
        } else if chat.isNewFriendship {
            usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
            detailsLabel.font = UIFont.boldSystemFont(ofSize: detailsTextFontSize)
            detailsLabel.text = "New friend" + timeAgoString
            cameraButton.tintColor = WKTheme.textColor
            statusIndicatorView.configure(forStatus: .none, isOpened: false, type: type, isNewFriendship: true)
            return
        }
        
//        if hasUnreads {
//            cameraButton.tintColor = WKTheme.textColor
//            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
//            detailsLabel.attributedText = attibutedText(detailsText: "New", detailsTextColor: textColor, timeAgoString: timeAgoString, isBold: true)
//            statusIndicatorView.configure(forStatus: .received, isOpened: false, type: type)
//            return
//        }
        
        else if isLastSender {
            switch chat.status {
            case .failed:
                detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
                detailsLabel.text = "Failed - Tap tap to retry"
                detailsLabel.textColor = .red
                statusIndicatorView.configure(forStatus: .failed)
            case .sending:
                cameraButton.tintColor = WKTheme.textColor
                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
                detailsLabel.text = "Sending - Do not close 🙏"
                statusIndicatorView.configure(forStatus: .sending, isOpened: false, type: type)
            case .delivered:
                cameraButton.tintColor = WKTheme.textColor
                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                detailsLabel.attributedText = attibutedText(detailsText: "Delivered", detailsTextColor: WKTheme.textColor, timeAgoString: timeAgoString)
                statusIndicatorView.configure(forStatus: .delivered, isOpened: false, type: type)
            case .opened:
                usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
                detailsLabel.attributedText = attibutedText(detailsText: "Opened", timeAgoString: timeAgoString)
                cameraButton.tintColor = WKTheme.textColor
                statusImageView.image = #imageLiteral(resourceName: "icons8-circled")
                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
                statusIndicatorView.configure(forStatus: .delivered, isOpened: true, type: type)
            default:
                ()
            }
            return
        } else {
            switch chat.status {
            case .delivered:
                cameraButton.tintColor = WKTheme.textColor
                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
                detailsLabel.attributedText = attibutedText(detailsText: "New \(chat.lastMessageSentType.rawValue.capitalized)", detailsTextColor: textColor, timeAgoString: timeAgoString, isBold: true)
                statusIndicatorView.configure(forStatus: .received, isOpened: false, type: type)
            case .opened:
                usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
                detailsLabel.attributedText = attibutedText(detailsText: "Opened", timeAgoString: timeAgoString)
                cameraButton.tintColor = WKTheme.textColor
                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
                detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
                statusIndicatorView.configure(forStatus: .received, isOpened: true, type: type)
            default:
                ()
            }
            return
        }
        
        if chat.status == .failed && isLastSender {
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            detailsLabel.text = "Failed - Tap tap to retry"
            detailsLabel.textColor = .red
            statusIndicatorView.configure(forStatus: .failed)
            return
        }
        
        if chat.isSending && isLastSender {
            cameraButton.tintColor = WKTheme.textColor
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            detailsLabel.text = "Sending - Do not close 🙏"
            statusIndicatorView.configure(forStatus: .sending, isOpened: false, type: type)
            
        } else if chat.isNewFriendship && !Date(timeIntervalSince1970: chat.lastChatUpdateTimestamp).isWithinThePastWeek() {
            detailsLabel.text = "Tap to chat" + timeAgoString
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            statusIndicatorView.configure(forStatus: .none, isOpened: false, type: type)
            
        } else if chat.isNewFriendship {
            usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
            detailsLabel.font = UIFont.boldSystemFont(ofSize: detailsTextFontSize)
            detailsLabel.text = "New friend" + timeAgoString
            cameraButton.tintColor = WKTheme.textColor
            statusIndicatorView.configure(forStatus: .none, isOpened: false, type: type, isNewFriendship: true)
            
        } else if chat.status == .delivered {
            cameraButton.tintColor = WKTheme.textColor
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.attributedText = attibutedText(detailsText: isLastSender ? "Delivered" : "New \(chat.lastMessageSentType.rawValue.capitalized))", detailsTextColor: WKTheme.textColor, timeAgoString: timeAgoString)
            statusIndicatorView.configure(forStatus: .delivered, isOpened: false, type: type)
            
        } else if chat.status == .opened {
        
            usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
            detailsLabel.attributedText = attibutedText(detailsText: isLastSender ? "Opened" : "Received", timeAgoString: timeAgoString)
            cameraButton.tintColor = WKTheme.textColor
            statusImageView.image = #imageLiteral(resourceName: "icons8-circled")
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            statusIndicatorView.configure(forStatus: isLastSender ? .delivered : .received, isOpened: true, type: type)
                    
        
//        else if !chat.isOpened {
//            if UserController.shared.currentUser!.uid == chat.lastSenderUid {
//                cameraButton.tintColor = WKTheme.textColor
//                usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
//                detailsLabel.attributedText = attibutedText(detailsText: "Delivered", detailsTextColor: WKTheme.textColor, timeAgoString: timeAgoString)
//                statusIndicatorView.configure(forStatus: .delivered, isOpened: false, type: type)
//
//            } else {
//                usernameLabel.font = UIFont.boldSystemFont(ofSize: 17)
//                detailsLabel.attributedText = attibutedText(detailsText: "New Message", detailsTextColor: textColor, timeAgoString: timeAgoString, isBold: true)
//                cameraButton.tintColor = .black
//                statusImageView.image = #imageLiteral(resourceName: "icons8-filled_circle")
//                statusIndicatorView.configure(forStatus: .received, isOpened: false, type: type)
//
//            }
        } else if chat.isOpened {
            let isSender = chat.lastSenderUid == UserController.shared.currentUser?.uid
            detailsLabel.text = "Opened" + timeAgoString
            cameraButton.tintColor = WKTheme.textColor
            statusImageView.image = #imageLiteral(resourceName: "icons8-circled")
            usernameLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
            detailsLabel.font = UIFont.systemFont(ofSize: detailsTextFontSize)
            statusIndicatorView.configure(forStatus: isSender ? .delivered : .received, isOpened: true, type: type)
        }
    
    }
    
    @objc private func handleCameraButton() {
        delegate?.didTapCameraButton(cameraButton)
    }
    
    let separatorView = UIView()
    func hideSeparatorView() {
        separatorView.isHidden = true
    }
}

// MARK: - UI
private extension FriendsListCell {
    func updateView() {
        backgroundColor = .white
        
        statusIndicatorView.configure(forStatus: .delivered, isOpened: false, type: .photo)
        
        let detailsStackView = UIStackView(arrangedSubviews: [statusIndicatorView, detailsLabel])
        detailsStackView.spacing = 8
        
        let textStackView = UIStackView(arrangedSubviews: [usernameLabel, detailsStackView])
        textStackView.axis = .vertical
        
        let overallStackView = UIStackView(arrangedSubviews: [profileImageView, textStackView, cameraButton])
        overallStackView.distribution = .fillProportionally
        overallStackView.spacing = 16
        
        addSubviews([overallStackView, unreadView])
        
        separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        overallStackView.anchorCenterYToSuperview()
        overallStackView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 8))
        
        unreadView.anchor(top: nil, leading: nil, bottom: nil, trailing: cameraButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 8), size: .init(width: 12, height: 12))
        unreadView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        
        
        separatorView.backgroundColor = WKTheme.ultraLightGray
        addSubview(separatorView)
        separatorView.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(), size: .init(width: frame.width, height: 1))
    }
}

