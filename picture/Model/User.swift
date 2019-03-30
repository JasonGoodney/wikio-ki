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
    
    var displayName: String
    let username: String
    let email: String
    let score: Int
    var profilePhotoUrl: String
    let uid: String
    
    var fcmToken: String? = nil
    
    var friendsUids: Set<String> = []
    
    var profilePhoto: UIImage?
    
    enum Keys {
        static let profilePhotoUrl = "profilePhotoUrl"
        static let email = "email"
        static let fcmToken = "fcmToken"
        static let displayName = "displayName"
    }
    
    init(dictionary: [String: Any]) {
        self.username = dictionary["username"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        self.profilePhotoUrl = dictionary["profilePhotoUrl"] as? String ?? ""
        self.uid = dictionary["uid"] as? String ?? ""
        self.score = dictionary["score"] as? Int ?? 0
        self.fcmToken = dictionary[Keys.fcmToken] as? String ?? nil
        self.displayName = dictionary[Keys.displayName] as? String ?? ""
        
        if self.displayName == "" {
            self.displayName = self.username
        }
    }
    
    init(username: String, email: String = "", score: Int = 0, uid: String = "", profilePhotoUrl: String = "") {
        self.username = username
        self.email = email
        self.score = score
        self.uid = uid
        self.profilePhotoUrl = profilePhotoUrl
        self.displayName = username
        cacheImage(for: URL(string: self.profilePhotoUrl)!)
    }
}

extension User {
    func addFriend(_ user: User) {
        Firestore.firestore()
            .collection(DatabaseService.Collection.users).document(uid)
            .collection(DatabaseService.Collection.friends).document(user.uid).setData([user.uid: true])
    }
    
    func cacheImage(for url: URL) {
        SDWebImageManager.shared().saveImage(toCache: profilePhoto, for: url)
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
