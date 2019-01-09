//
//  DatabaseService+AddFriend.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension DatabaseService {
    
    func removeFriend(_ friend: User, completion: @escaping ErrorCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        Firestore.firestore().collection(Collection.users).document(currentUser.uid).collection(Collection.friends).document(friend.uid).delete { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            print("removed \(friend.username) from \(currentUser.username)'s friend list")
            
            completion(nil)
        }
        
        changeUserChat(isActive: false, between: currentUser, andFriend: friend)
        
    }
}

private extension DatabaseService {
    func changeUserChat(isActive: Bool, between currentUser: User, andFriend friend: User) {
        let chatUid = Chat.chatUid(for: currentUser, and: friend)
        
        Firestore.firestore().collection(Collection.userChats).document(currentUser.uid).updateData([chatUid: isActive]) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("\(currentUser.username) is not active with \(friend.username)")
        }
        Firestore.firestore().collection(Collection.userChats).document(friend.uid).updateData([chatUid: isActive]) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("\(friend.username) is not active with \(currentUser.username)")
        }

    }
}
