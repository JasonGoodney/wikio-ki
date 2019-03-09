//
//  UIDevice.swift
//  picture
//
//  Created by Jason Goodney on 3/8/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

extension UIDevice {
    public class var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    public class var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
}
