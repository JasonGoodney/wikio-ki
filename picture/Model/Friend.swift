//
//  Friend.swift
//  picture
//
//  Created by Jason Goodney on 1/13/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class Friend: User {
    
    let isBestFriend: Bool
    
    enum Keys {
        static let isBestFriend = "isBestFriend"
    }
    
    override init(dictionary: [String : Any]) {
        self.isBestFriend = dictionary[Keys.isBestFriend] as? Bool ?? false
        
        super.init(dictionary: dictionary)
    }
    
    init(username: String, email: String, score: Int, uid: String, profilePhotoUrl: String, isBestFriend: Bool = false) {
        
        self.isBestFriend = isBestFriend
        
        super.init(username: username, email: email, score: score, uid: uid, profilePhotoUrl: profilePhotoUrl)
        
    }
}

