//
//  StatusIndicatorView.swift
//  picture
//
//  Created by Jason Goodney on 1/22/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class StatusIndicatorView: UIView {

    private let deliveredUnopened = #imageLiteral(resourceName: "forward_unopened").withRenderingMode(.alwaysTemplate)
    private let deliveredOpened = #imageLiteral(resourceName: "forward_opened").withRenderingMode(.alwaysTemplate)
    private let receivedUnopened = #imageLiteral(resourceName: "rounded-black-square-shape").withRenderingMode(.alwaysTemplate)
    private let receivedOpened = #imageLiteral(resourceName: "check-box-empty").withRenderingMode(.alwaysTemplate)
    
    private lazy var statusStackView = UIStackView(arrangedSubviews: [statusIndicator, sendingIndicatorView])
    
    private let sendingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.hidesWhenStopped = true
        view.color = WKTheme.textColor
//        view.heightAnchor.constraint(equalToConstant: 20).isActive = true
//        view.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return view
    }()
    
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
    
    func configure(forStatus status: MessageStatus, isOpened: Bool, type: MessageType) {

        if status == .sending {
            sendingIndicatorView.startAnimating()
            sendingIndicatorView.isHidden = false
            statusIndicator.isHidden = true
        } else if status == .delivered {
            
            sendingIndicatorView.stopAnimating()
            statusIndicator.isHidden = false

                if isOpened {
                    statusIndicator.image = deliveredOpened
                } else {
                    statusIndicator.image = deliveredUnopened
                }
        } else if status == .received {
            
            sendingIndicatorView.stopAnimating()
            statusIndicator.isHidden = false
            
            if isOpened {
                statusIndicator.image = receivedOpened
            } else {
                statusIndicator.image = receivedUnopened
                
            }
        }
        
        if type == .photo {
            statusIndicator.tintColor = WKTheme.photo
        } else {
            statusIndicator.tintColor = WKTheme.video
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
