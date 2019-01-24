//
//  GoToAddFriendCell.swift
//  picture
//
//  Created by Jason Goodney on 1/24/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

protocol GoToAddFriendCellDelegate: class {
    func handleGoToButton(_ sender: Any)
}

class GoToAddFriendCell: UITableViewCell, ReuseIdentifiable {
    
    weak var delegate: GoToAddFriendCellDelegate?
    
    private lazy var goToButton: PopButton = {
        let button = PopButton()
        button.setTitle("Add Friends", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.addTarget(self, action: #selector(goToButtonTapped), for: .touchUpInside)
        button.backgroundColor = WKTheme.buttonBlue
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(goToButton)
        
        goToButton.anchorCenterYToSuperview()
        goToButton.anchorCenterXToSuperview()
        
        goToButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        goToButton.widthAnchor.constraint(equalToConstant: 200).isActive = true
        goToButton.layer.cornerRadius = 28
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func goToButtonTapped(_ sender: Any) {
        delegate?.handleGoToButton(goToButton)
    }
}
