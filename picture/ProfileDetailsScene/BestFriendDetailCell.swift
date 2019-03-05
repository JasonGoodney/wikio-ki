//
//  BestFriendDetailCell.swift
//  picture
//
//  Created by Jason Goodney on 1/15/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class BestFriendDetailCell: CheckmarkToggleCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class SendToCell: CheckmarkToggleCell {
    
    let separatorView = UIView()
    func separatorView(isHidden: Bool) {
        separatorView.isHidden = isHidden
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        separatorView.backgroundColor = Theme.ultraLightGray
        addSubview(separatorView)
        separatorView.anchor(top: nil, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, padding: .init(), size: .init(width: 0, height: 1))
        
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func toggleOff() {
    
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn], animations: {
            self.selectionButton.setImage(#imageLiteral(resourceName: "icons8-circled").withRenderingMode(.alwaysTemplate), for: .normal)
            self.selectionButton.tintColor = Theme.gainsboro
            self.textLabel?.textColor = .black
            self.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        }, completion: nil)
    }
    
    override func toggleOn() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseIn], animations: {
            self.selectionButton.setImage(#imageLiteral(resourceName: "icons8-ok").withRenderingMode(.alwaysTemplate), for: .normal)
            self.selectionButton.tintColor = Theme.buttonBlue
            self.textLabel?.textColor = Theme.buttonBlue
            self.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        }, completion: nil)
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

    fileprivate lazy var selectionButton: PopButton = {
        let button = PopButton()
        button.isUserInteractionEnabled = false
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func toggleOn() {
        selectionButton.setImage(#imageLiteral(resourceName: "icons8-ok").withRenderingMode(.alwaysTemplate), for: .normal)
        selectionButton.tintColor = Theme.buttonBlue
    }
    
    func toggleOff() {
        selectionButton.setImage(#imageLiteral(resourceName: "icons8-circled").withRenderingMode(.alwaysTemplate), for: .normal)
        selectionButton.tintColor = Theme.gainsboro
    }
    
    private func setupLayout() {
        
        addSubview(selectionButton)
        selectionButton.anchorCenterYToSuperview()
        selectionButton.anchor(top: nil, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16), size: .init(width: 32, height: 32))
    }
    
}
