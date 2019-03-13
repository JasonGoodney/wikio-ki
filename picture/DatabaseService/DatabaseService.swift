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
        
    static func messagesReference(forPath path: String) -> CollectionReference {
        return Firestore.firestore().collection(Collection.chats).document(path).collection(Collection.messages)
    }
    
    static func friendRequestsReference(forPath path: String) -> CollectionReference {
        return Firestore.firestore().collection(Collection.users).document(path).collection(Collection.friendRequests)
    }
    
    static func sentRequestsReference(forPath path: String) -> CollectionReference {
        return Firestore.firestore().collection(Collection.users).document(path).collection(Collection.sentRequests)
    }
    
    static func chatReference(forPath path: String) -> DocumentReference {
        return Firestore.firestore().collection(Collection.chats).document(path)
    }
    
    static func userReference(forPathUid uid: String) -> DocumentReference {
        return Firestore.firestore().collection(Collection.users).document(uid)
    }
    
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
        static let sentMessages = "sentMessages"
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
            Firestore.firestore().collection(Collection.users).document(searchedUser.uid)
                .collection(Collection.blocked).document(UserController.shared.currentUser!.uid)
                .getDocument(completion: { (snapshot, error) in
                if let error = error {
                    print(error)
                    completion(nil, error)
                    return
                }
                    // The user being search for has block the user who is searching
                    if let snapshot = snapshot, snapshot.exists {
                        print("The user being search for has block the user who is searching")
                        completion(nil, nil)
                    } else {
                        print("Not Blocked")
                        completion(searchedUser, nil)
                    }
                
            })
            
            
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
    
    func updateDocument(_ document: DocumentReference, withFields fields: [String: Any], completion: @escaping ErrorCompletion) {
        
        document.setData(fields, merge: true) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            print("Updated fields for \(document.path)")
            completion(nil)
        }
    }
    
    func updateData(_ document: DocumentReference, withFields fields: [String: Any], completion: @escaping ErrorCompletion) {
        
        document.updateData(fields) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            print("Updated fields for \(document.path)")
            completion(nil)
        }
    }
}
