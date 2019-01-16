//
//  AddFriendButton.swift
//  picture
//
//  Created by Jason Goodney on 12/26/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

class AddFriendButton: PopButton {
    
    private let title: String
    weak var delegate: AddFriendDelegate?
    var addFriendState: AddFriendState
    
    init(title: String, addFriendState: AddFriendState) {
        self.title = title
        self.addFriendState = addFriendState
        super.init(frame: .zero)
        
        setTitle(title, for: .normal)
        setTitleColor(WKTheme.textColor, for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if addFriendState == .accepted {
            isUserInteractionEnabled = false
        }
        super.touchesBegan(touches, with: event)
    }
}
