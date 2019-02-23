//
//  UnreadView.swift
//  picture
//
//  Created by Jason Goodney on 1/19/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class UnreadView: UIView {
    
    var unreadCount = 0 {
        didSet {
            if unreadCount == 0 {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                    self.alpha = 0
                }, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut], animations: {
                    self.alpha = 1
                }, completion: nil)
                unreadLabel.text = "\(unreadCount)"
            } 
        }
    }
    
    private let unreadLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.backgroundColor = WKTheme.buttonBlue
        label.textAlignment = .center
        let height: CGFloat = 20
        label.heightAnchor.constraint(equalToConstant: height).isActive = true
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
        label.layer.cornerRadius = height / 2
        label.clipsToBounds = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        alpha = 0
        
        addSubview(unreadLabel)
        
        unreadLabel.anchor(top: topAnchor, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 4, bottom: 0, right: 4))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    
}
