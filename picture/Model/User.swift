//
//  User.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore
import SDWebImage

class User {
    
    let username: String
    let email: String
    let score: Int
    let profilePhotoUrl: String
    let uid: String
    
    var friendsUids: Set<String> = []
    
    init(dictionary: [String: Any]) {
        self.username = dictionary["username"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.profilePhotoUrl = dictionary["profilePhotoUrl"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.score = dictionary["score"] as? Int ?? 0
    }
    
    init(username: String, email: String = "", score: Int = 0, uid: String = "", profilePhotoUrl: String = "") {
        self.username = username
        self.email = email
        self.score = score
        self.profilePhotoUrl = profilePhotoUrl
        self.uid = uid
    }
}

extension User {
    func addFriend(_ user: User) {
        Firestore.firestore()
            .collection(DatabaseService.Collection.users).document(uid)
            .collection(DatabaseService.Collection.friends).document(user.uid).setData([user.uid: true])
    }
}

extension User: Equatable, Hashable {
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    var hashValue: Int {
        return uid.hashValue ^ profilePhotoUrl.hashValue
    }
}
