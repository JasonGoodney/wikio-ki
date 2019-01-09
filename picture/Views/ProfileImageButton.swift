//
//  ProfileImageButton.swift
//  picture
//
//  Created by Jason Goodney on 1/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class ProfileImageButton: UIButton {

    init(height: CGFloat, width: CGFloat, enabled: Bool = true) {
        super.init(frame: .zero)
        
        isUserInteractionEnabled = enabled
        heightAnchor.constraint(equalToConstant: height).isActive = true
        widthAnchor.constraint(equalToConstant: width).isActive = true
        layer.cornerRadius = min(width, height) / 2
        clipsToBounds = true
        backgroundColor = .lightGray
        imageView?.contentMode = .scaleAspectFill

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
