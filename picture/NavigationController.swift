//
//  NavigationController.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .black)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = navigationItem.title
        navigationItem.titleView = titleLabel
        
        navigationBar.tintColor = .black
    }

}
