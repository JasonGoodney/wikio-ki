//
//  BestFriendDetailCell.swift
//  picture
//
//  Created by Jason Goodney on 1/15/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class BestFriendDetailCell: CheckmarkToggleCell {}

class SendToCell: CheckmarkToggleCell {
    
    let separatorView = UIView()
    func separatorView(isHidden: Bool) {
        separatorView.isHidden = isHidden
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        separatorView.backgroundColor = Theme.ultraLightGray
        addSubview(separatorView)
        separatorView.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(), size: .init(width: frame.width, height: 1))
        
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class CheckmarkToggleCell: UITableViewCell, ReuseIdentifiable {

    override var isSelected: Bool {
        didSet {
            if isSelected {
                toggleOn()
            } else {
                toggleOff()
            }
        }
    }

    private lazy var selectionButton: PopButton = {
        let button = PopButton()
        button.isUserInteractionEnabled = false
        return button
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(selectionButton)
        
        selectionButton.anchorCenterYToSuperview()
        selectionButton.anchor(top: nil, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16), size: .init(width: 32, height: 32))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toggleOn() {
        selectionButton.setImage(#imageLiteral(resourceName: "icons8-ok").withRenderingMode(.alwaysTemplate), for: .normal)
        selectionButton.tintColor = Theme.buttonBlue
        selectionButton.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
    }
    
    func toggleOff() {
        selectionButton.setImage(#imageLiteral(resourceName: "icons8-circled").withRenderingMode(.alwaysTemplate), for: .normal)
        selectionButton.tintColor = Theme.gainsboro
        selectionButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
    }
    
}
