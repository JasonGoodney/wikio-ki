//
//  UserController.swift
//  picture
//
//  Created by Jason Goodney on 12/24/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import Firebase

class UserController {
    
    static let shared = UserController(); private init() {}
    
    var currentUser: User?
    
    var blockedUids: [String] = []
    
    func fetchCurrentUser(completion: @escaping (Bool) -> Void = { _ in }) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(false)
                return
            }
            
            let dbs = DatabaseService()
            dbs.fetchBlocked(completion: { (blocked, error) in
                if let error = error {
                    print(error)
                    completion(false)
                    return
                }
                
                self.blockedUids = blocked ?? []
            })
            
            guard let dictionary = snapshot?.data() else { return }
            self.currentUser = User(dictionary: dictionary)
            print(self.currentUser?.username, self.currentUser?.email)
            completion(true)
            
            
        }
    }
    
}
