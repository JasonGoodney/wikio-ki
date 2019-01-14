//
//  DatabaseService.swift
//  picture
//
//  Created by Jason Goodney on 12/28/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

class DatabaseService {
    
    enum Collection {
        static let chats = "chats"
        static let messages = "messages"
        static let userChats = "userChats"
        static let users = "users"
        static let takenUsernames = "takenUsernames"
        
        static let friends = "friends"
        static let friendRequests = "friendRequests"
        static let sentRequests = "sentRequests"
        static let blocked = "blocked"
    }
    
    func fetchSearchedUser(with searchText: String, completion: @escaping (User?, Error?) -> Void) {
        Firestore.firestore().collection(Collection.users).whereField("username", isEqualTo: searchText).getDocuments { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            guard let docDataDict = docs.first?.data() else { return }
            let searchedUser = User(dictionary: docDataDict)
            
            completion(searchedUser, nil)
        }
    }
    
    func updateUser(withFields fields: [String: Any], completion: @escaping ErrorCompletion) {
        
        guard let uid = UserController.shared.currentUser?.uid else { return }
        Firestore.firestore().collection(Collection.users).document(uid).setData(fields, merge: true) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            print("Updated fields for user")
            completion(nil)
        }
    }
}
