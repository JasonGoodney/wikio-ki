//
//  DatabaseService+DeleteAccount.swift
//  picture
//
//  Created by Jason Goodney on 1/11/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

extension DatabaseService {
    
    func deleteAccount() {
        guard let user = UserController.shared.currentUser else { return }
        
        for friendUid in user.friendsUids {
            Firestore.firestore()
                .collection(Collection.users).document(friendUid)
                .collection(Collection.friends).document(user.uid).delete { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("💫\(user.username) removed from \(friendUid)'s friends lists")
            }
            let chatUid = Chat.chatUid(for: user.uid, and: friendUid)
            Firestore.firestore().collection(Collection.chats).document(chatUid).delete { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("💫removed chat for \(chatUid)")
            }
            
            Firestore.firestore().collection(Collection.userChats).document(friendUid)
                .updateData([chatUid: FieldValue.delete()]) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("💫removed chat \(chatUid)")
            }
        }
        
        Firestore.firestore().collection(Collection.userChats).document(user.uid).delete { (error) in
            if let error = error {
                print(error)
                return
            }
            print("💫removed user chat for \(user.username) \(user.uid)")
        }
        
        Firestore.firestore().collection(Collection.users).document(user.uid).delete { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("💫removed user \(user.username) \(user.uid)")
        }
        
        Auth.auth().currentUser?.delete(completion: { (error) in
            if let error = error {
                print(error)
                return
            }
            print("💫 account deleted")
        })
    }
    
    fileprivate func removeFromFriendsLists(user: User) {
        
        
        
    }
    
    fileprivate func removeChat(user: User) {
        
    }
    
    fileprivate func removeMessages(user: User) {
        Firestore.firestore().collection(Collection.messages).document(user.uid).delete { (error) in
            if let error = error {
                print(error)
                return
            }
        }
    }
}
