//
//  OpenMessageView.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

// <div>Icons made by <a href="https://www.flaticon.com/authors/pixel-perfect" title="Pixel perfect">Pixel perfect</a> from <a href="https://www.flaticon.com/"                 title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/"                 title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></div>

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
        label.textColor = WKTheme.textColor
        return label
    }()
    
    private let deliveredUnopened = #imageLiteral(resourceName: "iconfinder_web_9_3924904").withRenderingMode(.alwaysTemplate)
    private let deliveredOpened = #imageLiteral(resourceName: "iconfinder_send_3936856").withRenderingMode(.alwaysTemplate)
    private let receivedUnopened = #imageLiteral(resourceName: "rounded-black-square-shape").withRenderingMode(.alwaysTemplate)
    private let receivedOpened = #imageLiteral(resourceName: "check-box-empty").withRenderingMode(.alwaysTemplate)
    
    private lazy var statusStackView = UIStackView(arrangedSubviews: [statusIndicator, sendingIndicatorView])
    
    private let sendingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = true
        view.color = WKTheme.textColor
        view.heightAnchor.constraint(equalToConstant: 20).isActive = true
        view.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return view
    }()
    
    private let statusIndicator: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var openMessageGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(openMessageGestureTapped))
        return gesture
    }()
    
    private let statusIndicatorView = StatusIndicatorView(subviewSize: 20)
    
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
        let captionText = message.caption == "" ? "" : ": \(message.caption!)"
        if message.status == .sending {
            statusLabel.text = "Sending - Do not close 🙏"

            statusIndicatorView.configure(forStatus: .sending, isOpened: message.isOpened, type: message.messageType)
        } else if message.status == .delivered || message.status == .none {

            if message.senderUid == UserController.shared.currentUser?.uid {
                if message.isOpened {

                    statusIndicatorView.configure(forStatus: .delivered, isOpened: message.isOpened, type: message.messageType)
                    statusLabel.text = "Opened\(captionText)"
                } else {

                    statusIndicatorView.configure(forStatus: .delivered, isOpened: message.isOpened, type: message.messageType)
                    statusLabel.text = "Delivered\(captionText)"
                }
            } else {
                if message.isOpened {

                    statusIndicatorView.configure(forStatus: .received, isOpened: message.isOpened, type: message.messageType)
                    statusLabel.text = "Opened\(captionText)"
                } else {

                    statusIndicatorView.configure(forStatus: .received, isOpened: message.isOpened, type: message.messageType)
                    statusLabel.text = "Received\(captionText)"
                }
            }
        }
    }
}

// MARK: - UI
private extension OpenMessageView {
    
    func updateView() {
        addSubviews([statusLabel, statusIndicatorView])
    
        statusIndicatorView.anchorCenterYToSuperview()
        statusIndicatorView.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 8, bottom: 0, right: 0), size: .init(width: 20, height: 20))
        
        statusLabel.anchorCenterYToSuperview()
        statusLabel.anchor(top: nil, leading: statusIndicatorView.trailingAnchor, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 8, bottom: 0, right: 16))

    }
}


