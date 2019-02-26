//
//  PopButton.swift
//  picture
//
//  Created by Jason Goodney on 1/15/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class PopButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize))
        
        layer.cornerRadius = buttonSize / 2
        
        adjustsImageWhenHighlighted = false        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pop()
        super.touchesBegan(touches, with: event)
    }
    
    func pop(completion: @escaping () -> () = { }) {
        
        UIView.animate(withDuration: 0.1,
                       animations: {
                        self.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        },
                       completion: { _ in
                        UIView.animate(withDuration: 0.1) {
                            self.transform = CGAffineTransform.identity
                            
                            completion()
                        }
        })
    }
    
    func setIsSelected(_ selected: Bool, bgColor: UIColor = .clear, tintColor: UIColor = .white) {

        if selected {
            self.backgroundColor = bgColor
            self.tintColor = tintColor
            self.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        } else {
            self.backgroundColor = bgColor
            self.tintColor = tintColor
            self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
}
