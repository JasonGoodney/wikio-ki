//
//  PopButton.swift
//  picture
//
//  Created by Jason Goodney on 1/15/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class PopButton: UIButton {
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
}
