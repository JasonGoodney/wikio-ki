//
//  StatusIndicatorView.swift
//  picture
//
//  Created by Jason Goodney on 1/22/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class StatusIndicatorView: UIView {

    private let deliveredUnopened = #imageLiteral(resourceName: "iconfinder_web_9_3924904").withRenderingMode(.alwaysTemplate)
    private let deliveredOpened = #imageLiteral(resourceName: "iconfinder_send_3936856").withRenderingMode(.alwaysTemplate)
    private let receivedUnopened = #imageLiteral(resourceName: "rounded-black-square-shape").withRenderingMode(.alwaysTemplate)
    private let receivedOpened = #imageLiteral(resourceName: "check-box-empty").withRenderingMode(.alwaysTemplate)
    private let tapToChat = #imageLiteral(resourceName: "icons8-topic").withRenderingMode(.alwaysTemplate)
    private let newFriendship = #imageLiteral(resourceName: "icons8-speech_bubble").withRenderingMode(.alwaysTemplate)
    private let failed = #imageLiteral(resourceName: "icons8-exclamation_mark").withRenderingMode(.alwaysTemplate)
    
    private lazy var statusStackView = UIStackView(arrangedSubviews: [statusIndicator, sendingIndicatorView])
    
    private let sendingIndicatorView = NVActivityIndicatorView(frame: .zero, type: .lineSpinFadeLoader, color: Theme.textColor, padding: nil)

    
    private let statusIndicator: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private let subviewSize: CGFloat
    
    init(subviewSize: CGFloat) {
        self.subviewSize = subviewSize
        super.init(frame: .zero)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(forStatus status: MessageStatus, isOpened: Bool = false, type: MessageType = .none, isNewFriendship: Bool = false) {

        if status == .failed {
            statusIndicator.tintColor = .red
            statusIndicator.image = failed
            return
        }
        
        if status == .sending {
            sendingIndicatorView.startAnimating()
            sendingIndicatorView.isHidden = false
            statusIndicator.isHidden = true
        } else if status == .delivered {
            
            sendingIndicatorView.stopAnimating()
            statusIndicator.isHidden = false
            statusIndicator.image = isOpened ? deliveredOpened : deliveredUnopened

        } else if status == .received {
            
            sendingIndicatorView.stopAnimating()
            statusIndicator.isHidden = false
            statusIndicator.image = isOpened ? receivedOpened : receivedUnopened

        } else if status == .none {
            statusIndicator.image = isNewFriendship ? newFriendship : tapToChat
        }
        
        if type == .photo {
            statusIndicator.tintColor = Theme.photo
        } else if type == .video {
            statusIndicator.tintColor = Theme.video
        } else {
            statusIndicator.tintColor = Theme.textColor
        }
    }
    
    private func setupLayout() {
        addSubview(statusStackView)
        
        sendingIndicatorView.heightAnchor.constraint(equalToConstant: subviewSize).isActive = true
        sendingIndicatorView.widthAnchor.constraint(equalToConstant: subviewSize).isActive = true
        
        statusIndicator.heightAnchor.constraint(equalToConstant: subviewSize).isActive = true
        statusIndicator.widthAnchor.constraint(equalToConstant: subviewSize).isActive = true
        
        statusStackView.anchorCenterYToSuperview()
        statusStackView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
    }
}
