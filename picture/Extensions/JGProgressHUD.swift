//
//  JGProgressHUD.swift
//  picture
//
//  Created by Jason Goodney on 1/17/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import JGProgressHUD

extension JGProgressHUD {
    func dismiss(afterDelay delay: TimeInterval, completion: @escaping () -> () = { }) {
        self.dismiss(afterDelay: delay)
    }
}
