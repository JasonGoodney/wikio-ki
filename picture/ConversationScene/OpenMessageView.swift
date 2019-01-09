//
//  OpenMessageView.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

protocol OpenMessageViewDelegate: class {
    func openMessage(_ recognizer: UITapGestureRecognizer)
}

class OpenMessageView: UIView {
    weak var delegate: OpenMessageViewDelegate?
    
    var message: Message? {
        didSet {
           // configureProperties()
        }
    }
    
    private let statusLabel: UILabel = {
        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .lightGray
        return label
    }()
    
    private let statusIndicator: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "icons8-filled_circle")
        return imageView
    }()
    
    private lazy var openMessageGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(openMessageGestureTapped))
        return gesture
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func openMessageGestureTapped(_ recognizer: UITapGestureRecognizer) {
        delegate?.openMessage(recognizer)
    }
    
    func configure(withTitle title: String) {
        
        statusLabel.text = title
    }
    
    func configure(withMessage message: Message) {
        if message.caption != nil && message.caption != "" {
            statusLabel.text = message.caption!
        } else if message.messageType == .photo {
            statusLabel.text = "New photo"
        } else if message.messageType == .video {
            statusLabel.text = "New video"
        }
        
        if message.senderUid == UserController.shared.currentUser?.uid {
            if message.isOpened {
                statusIndicator.image = #imageLiteral(resourceName: "message_sent_opened")
            } else {
                statusIndicator.image = #imageLiteral(resourceName: "paper_plane")
            }
        } else {
            if message.isOpened {
                statusIndicator.image = #imageLiteral(resourceName: "recieved_opened")
            } else {
                statusIndicator.image = #imageLiteral(resourceName: "icons8-stop")
            }
        }
    }
}

// MARK: - UI
private extension OpenMessageView {
    
    func updateView() {
        addSubviews(statusLabel, statusIndicator)
    
        statusIndicator.anchorCenterYToSuperview()
        statusIndicator.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 8, bottom: 0, right: 0), size: .init(width: 24, height: 24))
        
        statusLabel.anchorCenterYToSuperview()
        statusLabel.anchor(top: nil, leading: statusIndicator.trailingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 8, bottom: 0, right: 16))

    }
}


