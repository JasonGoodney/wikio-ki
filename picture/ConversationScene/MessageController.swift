//
//  MessageController.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation

class MessageController {
    static let shared = MessageController(); private init() {}
    
    var messages: [Message] = []
}
