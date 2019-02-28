//
//  Bundle.swift
//  picture
//
//  Created by Jason Goodney on 2/28/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation

extension Bundle {
    static func appName() -> String {
        guard let dictionary = Bundle.main.infoDictionary else {
            return ""
        }
        if let version : String = dictionary["CFBundleDisplayName"] as? String {
            return version
        } else {
            return ""
        }
    }
}
