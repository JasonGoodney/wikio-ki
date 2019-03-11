//
//  DatabaseService+Report.swift
//  picture
//
//  Created by Jason Goodney on 3/11/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension DatabaseService {
    
    func report(user: User, forReason reason: UserReportReason, completion: @escaping ErrorCompletion) {
        guard let reportedBy = UserController.shared.currentUser else { return }
        let reportedByElement: Any = [reportedBy.uid: reasonString(reason)]

        let ref = Firestore.firestore().collection("reports").document(user.uid)
        let fields: [String: Any] = [
            "username": user.username,
            "reportedBy": FieldValue.arrayUnion([reportedByElement])
        ]
        
        updateData(ref, withFields: fields, completion: { (error) in
            if let error = error {
                print("Error updating data: \(error)")
                if error._code == 5 {
                    self.updateDocument(ref, withFields: fields, completion: { (error) in
                        if let error = error {
                            print("Error setting data: \(error)")
                            completion(error)
                            return
                        }
                        print("👊 User was reported: set")
                        completion(nil)
                        return
                    })
                } else {
                    completion(error)
                    return
                }
            }

            print("👊 User was reported: update")
            completion(nil)
        })
    }
    
    fileprivate func reasonString(_ reason: UserReportReason) -> String {
        switch reason {
        case .hatefulContent:
            return "HATEFUL CONTENT"
        case .spamContent:
            return "SPAM CONTENT"
        case .sensitiveContent:
            return "SENSITIVE CONTENT"
        case .hackedAccount:
            return "ACCOUNT APPEARS TO BE HACKED"
        case .impersonationAcount:
            return "ACCOUNT IS IMPERSONATING ME OR SOMEONE ELSE"
        }
    }
}
