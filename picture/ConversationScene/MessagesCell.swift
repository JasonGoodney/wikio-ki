//
//  ConversationCell.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SDWebImage

protocol MessageCellDelegate: class {
    func loadMedia(for cell: MessagesCell, message: Message)
}

class MessagesCell: UICollectionViewCell, ReuseIdentifiable {

    weak var delegate: MessageCellDelegate?
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .light)
        label.textColor = WKTheme.darkGray
        return label
    }()
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        return view
    }()
    
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        view.layer.cornerRadius = 1
        return view
    }()
    
    let openMessageView: OpenMessageView = {
        let view = OpenMessageView(frame: .zero)
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 0.75
        view.layer.borderColor = WKTheme.gainsboro.cgColor
        view.heightAnchor.constraint(equalToConstant: 56).isActive = true
        return view
    }()
    
    lazy var messagesStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [openMessageView])
        stackView.axis = .vertical
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with message: Message, from sender: User) {
  
        if sender.uid == UserController.shared.currentUser?.uid {
            usernameLabel.text = "ME"
            usernameLabel.textColor = WKTheme.meColor
            separatorView.backgroundColor = WKTheme.meColor
            
        } else {
            usernameLabel.text = sender.username.uppercased()
            usernameLabel.textColor = WKTheme.friendColor
            separatorView.backgroundColor = WKTheme.friendColor
        }
        
        openMessageView.configure(withMessage: message)
        timestampLabel.text = Date(timeIntervalSince1970: message.timestamp).messageDateTimestamp()
    }
    
    func messageIsSendingWarning() {
        openMessageView.shake()
    }
}

// MARK: - UI
private extension MessagesCell {
    func updateView() {
        let topStackView = UIStackView(arrangedSubviews: [usernameLabel, timestampLabel])
        topStackView.distribution = .equalSpacing
        addSubviews(topStackView, separatorView, messagesStackView)

        let cellHeight: CGFloat = 88
        let separatorHeight: CGFloat = 56
        let topStackViewHeight: CGFloat = cellHeight - separatorHeight - 8
        
        topStackView.anchor(top: topAnchor, leading: leadingAnchor, bottom: messagesStackView.topAnchor, trailing: trailingAnchor, padding: .init(top: 4, left: 7, bottom: 4, right: 16), size: .init(width: 0, height: topStackViewHeight))
        
        separatorView.anchor(top: topStackView.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: nil, padding: .init(top: 4, left: 8, bottom: 0, right: 0), size: .init(width: 2, height: separatorHeight))
        
        
        messagesStackView.anchor(top: separatorView.topAnchor, leading: separatorView.trailingAnchor, bottom: separatorView.bottomAnchor, trailing: trailingAnchor, padding: .init(top: 8, left: 8, bottom: 8, right: 16))

    }
}
