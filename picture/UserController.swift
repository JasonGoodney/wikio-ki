//
//  UserController.swift
//  picture
//
//  Created by Jason Goodney on 12/24/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import Firebase

class UserController: LoginFlowHandler {
    
    static let shared = UserController(); private init() {}
    
    var currentUser: User?
    
    var blockedUids: [String] = []
    var bestFriendsChats: [ChatWithFriend] {
        return allChatsWithFriends.filter { $0.friend.isBestFriend }
    }
//    var recentChatsWithFriends: [ChatWithFriend] {
//        return allChatsWithFriends.filter {
//            !bestFriendsChats.contains($0)
//                && Date(timeIntervalSince1970: $0.lastChatUpdateTimestamp).isWithinThePast24Hours()
//        }
//    }
    var allChatsWithFriends: [ChatWithFriend] = []
    
    func fetchCurrentUser(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection(DatabaseService.Collection.users).document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(false)
                return
            }
            
            guard let dictionary = snapshot?.data() else {
                print("user data not found, logging out Auth.auth().currentUser")
                self.handleLogout()
                return
            }
            
            self.currentUser = User(dictionary: dictionary)
            
            let dbs = DatabaseService()
            if uid == self.currentUser?.uid {
                dbs.fetchBlocked(for: uid, completion: { (blocked, error) in
                    if let error = error {
                        print(error)
                        completion(false)
                        return
                    }
                    
                    self.blockedUids = blocked ?? []
                })
            } else {
                print("uids do not match. did not fetch blocked users for \(self.currentUser!.uid)")
            }

            completion(true)
            
            
        }
    }
    
}
