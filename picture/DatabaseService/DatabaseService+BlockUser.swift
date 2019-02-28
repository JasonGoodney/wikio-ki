//
//  DatabaseService+BlockUser.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension DatabaseService {
    
    func block(user: User, completion: @escaping ErrorCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return }
        UserController.shared.allChatsWithFriends.removeAll(where: { $0.friend == user })
        
        changeUserChat(isActive: false, between: currentUser, andFriend: user)
        
        let blockData: [String: Any] = [user.uid: true]
        
        Firestore.firestore().collection(Collection.users).document(currentUser.uid)
            .collection(Collection.blocked).document(user.uid).setData(blockData) { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                
                print("\(currentUser.username) blocked \(user.username)")
                
                let document = Firestore.firestore().collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid).collection(DatabaseService.Collection.friends).document(user.uid)
                
                self.updateDocument(document, withFields: ["isBestFriend": false], completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    UserController.shared.bestFriendUids.removeAll(where: { $0 == user.uid })
                    print("Blocked user and no longer best friends")
                    completion(nil)
                })
        }
    }
    
    func unblock(user: User, completion: @escaping ErrorCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return }
        
        changeUserChat(isActive: true, between: currentUser, andFriend: user)
        
        Firestore.firestore().collection(Collection.users).document(currentUser.uid)
            .collection(Collection.blocked).document(user.uid).delete { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                
                print("remove \(user.username) from \(currentUser.username)'s block list")
                
                UserController.shared.blockedUids.removeAll(where: { (uid) -> Bool in
                    return uid == user.uid
                })
    
                
                completion(nil)
        }
    }
    
    
    func fetchBlocked(for userUid: String = (UserController.shared.currentUser?.uid)!, completion: @escaping ([String]?, Error?) -> Void) {
        Firestore.firestore()
            .collection(Collection.users).document(userUid)
            .collection(Collection.blocked).getDocuments { (snapshot, error) in
                if let error = error {
                    print(error)
                    completion(nil, error)
                    return
                }
               
                let docs = snapshot?.documents
                var blocked: [String] = []
                docs?.forEach({ (doc) in
                    let dict = doc.data()
                    guard let uid = dict.keys.first else { return }
                    blocked.append(uid)
                    completion(blocked, nil)
                })
        }
    }
}
