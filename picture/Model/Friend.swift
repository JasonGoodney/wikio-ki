//
//  Friend.swift
//  picture
//
//  Created by Jason Goodney on 1/13/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class Friend: User {
    
    var isBestFriend: Bool
    
    enum Keys {
        static let isBestFriend = "isBestFriend"
    }
    
    override init(dictionary: [String : Any]) {
        self.isBestFriend = dictionary[Keys.isBestFriend] as? Bool ?? false
        
        super.init(dictionary: dictionary)
    }
    
    init(user: User, isBestFriend: Bool = false) {
        
        self.isBestFriend = isBestFriend
        
        super.init(username: user.username, displayName: user.displayName, email: user.email, score: user.score, uid: user.uid, profilePhotoUrl: user.profilePhotoUrl)
        
    }
}

