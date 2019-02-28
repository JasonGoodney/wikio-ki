//
//  UserController.swift
//  picture
//
//  Created by Jason Goodney on 12/24/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import Firebase

typealias FirebaseUser = FirebaseAuth.User

class UserController: LoginFlowHandler {
    
    static let shared = UserController(); private init() {}

    var currentUser: User?
    
    var firebaseUser: FirebaseUser?
    
    var blockedUids: [String] = []
    
    var bestFriendUids: [String] = []
    
    var bestFriendsChats: [ChatWithFriend] = []

    var recentChatsWithFriends: [ChatWithFriend] = []
    
    var allChatsWithFriends: [ChatWithFriend] = [] {
        didSet {
            let bestFriends = allChatsWithFriends.filter { bestFriendUids.contains($0.friend.uid) }
            
            bestFriendsChats = bestFriends.sorted(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                return chatWithFriend1.chat.lastChatUpdateTimestamp > chatWithFriend2.chat.lastChatUpdateTimestamp
            })
            
            let recents = allChatsWithFriends.filter {
                Date(timeIntervalSince1970: $0.chat.lastChatUpdateTimestamp).isWithinThePast24Hours()
//                                    Date(timeIntervalSince1970: $0.chat.lastChatUpdateTimestamp).testingIsWithinRecentTime()
                    && !bestFriendUids.contains($0.friend.uid)
            }
            
            recentChatsWithFriends = recents.sorted(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                return chatWithFriend1.chat.lastChatUpdateTimestamp > chatWithFriend2.chat.lastChatUpdateTimestamp
            })
            
            
        }
    }
    
    func fetchCurrentUser(completion: @escaping (Bool) -> Void = { _ in }) {
        let _ = Auth.auth().addStateDidChangeListener { (auth, user) in
            
            guard let uid = user?.uid else { return }
            
            self.firebaseUser = user
            
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
    
}

// MARK: - Log out deinit
extension UserController {
    func dispose() {
        bestFriendUids = []
        blockedUids = []
        allChatsWithFriends = []
        currentUser = nil
    }
}
