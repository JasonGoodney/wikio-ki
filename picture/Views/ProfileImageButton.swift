//
//  ProfileImageButton.swift
//  picture
//
//  Created by Jason Goodney on 1/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

protocol ProfileImageButtonDelegate: class {
    func didTapProfileImageButton(_ sender: ProfileImageButton)
}

let placeholderProfileImage = UIImage(named: "placeholderProfileImage")?.withRenderingMode(.alwaysTemplate)

class ProfileImageButton: PopButton {

    weak var delegate: ProfileImageButtonDelegate?
    
    init(height: CGFloat, width: CGFloat, enabled: Bool = false) {
        super.init(frame: .zero)
        
        isUserInteractionEnabled = enabled
        heightAnchor.constraint(equalToConstant: height).isActive = true
        widthAnchor.constraint(equalToConstant: width).isActive = true
        layer.cornerRadius = min(width, height) / 2
        clipsToBounds = true
//        backgroundColor = .lightGray
        imageView?.contentMode = .scaleAspectFill
        setImage(placeholderProfileImage, for: .normal)
        tintColor = WKTheme.textColor

        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    @objc private func handleTap() {
        delegate?.didTapProfileImageButton(self)
    }
}
