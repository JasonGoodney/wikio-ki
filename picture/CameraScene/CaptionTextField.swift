//
//  CaptionTextField.swift
//  picture
//
//  Created by Jason Goodney on 12/14/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

protocol CaptionTextFieldDelegate: class {
    
}

class CaptionTextField: UITextField {
    
    weak var captionDelegate: CaptionTextFieldDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    

}
