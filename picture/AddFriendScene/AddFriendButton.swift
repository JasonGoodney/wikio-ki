//
//  AddFriendButton.swift
//  picture
//
//  Created by Jason Goodney on 12/26/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

class AddFriendButton: UIButton {
    
    private let title: String
    
    var addFriendState: AddFriendState
    
    init(title: String, addFriendState: AddFriendState) {
        self.title = title
        self.addFriendState = addFriendState
        super.init(frame: .zero)
        
        setTitle(title, for: .normal)
        setTitleColor(#colorLiteral(red: 0.7137254902, green: 0.7568627451, blue: 0.8, alpha: 1), for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        layer.borderWidth = 1
        layer.borderColor = #colorLiteral(red: 0.7137254902, green: 0.7568627451, blue: 0.8, alpha: 1).cgColor
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
}
