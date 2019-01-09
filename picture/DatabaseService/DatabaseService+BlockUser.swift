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
        
        let blockData: [String: Any] = [user.uid: true]
        
        Firestore.firestore().collection(Collection.users).document(currentUser.uid)
            .collection(Collection.blocked).document(user.uid).setData(blockData) { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                
                print("\(currentUser.username) blocked \(user.username)")
                completion(nil)
        }
    }
    
    func unblock(user: User, completion: @escaping ErrorCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return }

        Firestore.firestore().collection(Collection.users).document(currentUser.uid)
            .collection(Collection.blocked).document(user.uid).delete { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                
                print("remove \(user.username) from \(currentUser.username)'s block list")
                completion(nil)
        }
    }
    
    
    func fetchBlocked(completion: @escaping ([String]?, Error?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return }
        Firestore.firestore()
            .collection(Collection.users).document(currentUser.uid)
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
