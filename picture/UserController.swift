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
    
    var bestFriendUids: [String] = []
    
    var bestFriendsChats: [ChatWithFriend] {
        get {
            let bestFriends = allChatsWithFriends.filter { bestFriendUids.contains($0.friend.uid) }
            
            return bestFriends.sorted(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                return chatWithFriend1.chat.lastChatUpdateTimestamp > chatWithFriend2.chat.lastChatUpdateTimestamp
            })
        }
    }
    var recentChatsWithFriends: [ChatWithFriend] {
        get {
            let recents = allChatsWithFriends.filter {
                Date(timeIntervalSince1970: $0.chat.lastChatUpdateTimestamp).isWithinThePast24Hours()
                && !bestFriendUids.contains($0.friend.uid)
            }
            
            return recents.sorted(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                return chatWithFriend1.chat.lastChatUpdateTimestamp > chatWithFriend2.chat.lastChatUpdateTimestamp
            })
        }
    }
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
                
                dbs.fetchBestFriends(for: uid, completion: { (bestFriends, error) in
                    if let error = error {
                        print(error)
                        completion(false)
                        return
                    }
                    
                    self.bestFriendUids = bestFriends ?? []
                })
            } else {
                print("uids do not match. did not fetch blocked users for \(self.currentUser!.uid)")
            }

            completion(true)
            
            
        }
    }
    
}
