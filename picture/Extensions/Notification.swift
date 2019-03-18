//
//  Notification.swift
//  picture
//
//  Created by Jason Goodney on 2/27/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation

extension Notification.Name {
    static var sendingMesssage: Notification.Name {
        return .init(rawValue: "SendingMessageNotification")
    }
    
    static var agreeToEULA: Notification.Name {
        return .init(rawValue: "AgreeToEULANotification")
    }
    
    static var disagreeWithEULA: Notification.Name {
        return .init(rawValue: "DisagreeWithEULANotification")
    }
}
