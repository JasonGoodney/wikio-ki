//
//  RoundRectTextField.swift
//  picture
//
//  Created by Jason Goodney on 12/21/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

class RoundRectTextField: UITextField {

    let padding: CGFloat
    let height: CGFloat
    
    init(padding: CGFloat = 16, height: CGFloat = 50) {
        self.padding = padding
        self.height = height
        super.init(frame: .zero)
        
        layer.cornerRadius = height / 2
        layer.borderWidth = 1
        layer.borderColor = WKTheme.gainsboro.cgColor
        backgroundColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return .init(width: 0, height: height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: padding, dy: 0)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: padding, dy: 0)
    }
}


