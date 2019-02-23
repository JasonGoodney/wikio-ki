//
//  AddFriendButton.swift
//  picture
//
//  Created by Jason Goodney on 12/26/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class AddFriendButton: PopButton {
    
    private let title: String
    weak var delegate: AddFriendDelegate?
    var addFriendState: AddFriendState {
        didSet {
            if addFriendState == .accepted {
                isUserInteractionEnabled = false
            }
        }
    }
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [sendingIndicatorView, plusImageView, textLabel])
        view.spacing = 4
        view.isUserInteractionEnabled = false
        view.isExclusiveTouch = false
        return view
    }()
    
    private let plusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "icons8-plus_math").withRenderingMode(.alwaysTemplate)
        imageView.tintColor = WKTheme.textColor
        imageView.isUserInteractionEnabled = false
        imageView.isExclusiveTouch = false
        return imageView
    }()
    
    private let sendingIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 13, height: 13), type: .lineSpinFadeLoader, color: WKTheme.textColor, padding: nil)
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = WKTheme.textColor
        label.isUserInteractionEnabled = false
        label.isExclusiveTouch = false
        return label
    }()
    
    init(title: String, addFriendState: AddFriendState) {
        self.title = title
        self.addFriendState = addFriendState
        super.init(frame: .zero)
        
        textLabel.text = title
        
        addSubview(stackView)
        
        plusImageView.heightAnchor.constraint(equalToConstant: 13).isActive = true
        plusImageView.widthAnchor.constraint(equalToConstant: 13).isActive = true
        plusImageView.isHidden = true
        
        sendingIndicatorView.isUserInteractionEnabled = false
        sendingIndicatorView.isExclusiveTouch = false
        sendingIndicatorView.heightAnchor.constraint(equalToConstant: 13).isActive = true
        sendingIndicatorView.widthAnchor.constraint(equalToConstant: 13).isActive = true
        
        sendingIndicatorView.isHidden = true
        
        stackView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(top: 0, left: 8, bottom: 0, right: 8))
        
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        layer.borderWidth = 1
        layer.borderColor = WKTheme.textColor.cgColor
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        heightAnchor.constraint(equalToConstant: 34).isActive = true
        
        layer.cornerRadius = 17
               
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override var intrinsicContentSize: CGSize {
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        let labelSize = titleLabel?.sizeThatFits(CGSize(width: frame.width, height: .greatestFiniteMagnitude)) ?? .zero
        let desiredButtonSize = CGSize(width: labelSize.width + titleEdgeInsets.left + titleEdgeInsets.right, height: labelSize.height + titleEdgeInsets.top + titleEdgeInsets.bottom)
        
        return desiredButtonSize
    }
    
    func loadingIndicator(_ show: Bool, for state: AddFriendState) {
        
        if show {
            sendingIndicatorView.startAnimating()
            sendingIndicatorView.isHidden = false
            textLabel.text = state.rawValue
        } else {
            sendingIndicatorView.stopAnimating()
            sendingIndicatorView.isHidden = true
            textLabel.text = "+ " + state.rawValue
        }
    }
    
    func removeLoadingIndicator() {
        sendingIndicatorView.isHidden = true
        sendingIndicatorView.stopAnimating()
    }
}
