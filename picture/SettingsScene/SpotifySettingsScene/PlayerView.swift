//
//  PlayerView.swift
//  picture
//
//  Created by Jason Goodney on 4/8/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class PlayerView: UIView {

    private lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "icons8-play").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = Theme.ultraDarkGray
        button.setTitleColor(Theme.ultraDarkGray, for: .normal)
        return button
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = Theme.ultraDarkGray
        button.setTitleColor(Theme.ultraDarkGray, for: .normal)
        return button
    }()
    
    private lazy var songInfoLabel: UILabel = {
        let label = UILabel()
        label.text = songInfo
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = Theme.ultraDarkGray
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    var songInfo: String = "" {
        didSet {
            songInfoLabel.text = songInfo
        }
    }
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        backgroundColor = .white
        layer.cornerRadius = 14
        addShadow(opacity: 0.4, radius: 4)
        
        addSubviews([likeButton, songInfoLabel, playButton])
        
        likeButton.anchor(top: nil, leading: leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0), size: .init(width: 24, height: 24))
        likeButton.anchorCenterYToSuperview()
        
        playButton.anchor(top: nil, leading: nil, bottom: nil, trailing: trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16), size: .init(width: 24, height: 24))
        playButton.anchorCenterYToSuperview()
        
        songInfoLabel.anchorCenterXToSuperview()
        songInfoLabel.anchorCenterYToSuperview()
        songInfoLabel.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 8)
        songInfoLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: 8)
        
    }
    
}
