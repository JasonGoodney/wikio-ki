//
//  NavigationTitleLabel.swift
//  picture
//
//  Created by Jason Goodney on 12/23/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

class NavigationTitleLabel: UILabel {
    
    init(title: String) {
        super.init(frame: .zero)
        
        text = title
        font = UIFont.systemFont(ofSize: 20, weight: .black)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
