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
        var fields: [String: Any] = [
            "username": user.username,
            "reportedBy": FieldValue.arrayUnion([reportedByElement]),
            "reportCount": 1
        ]
        
        Firestore.firestore().runTransaction({ (transaction, errorPointer) -> Any? in
            let reportDocument: DocumentSnapshot
            do {
                try reportDocument = transaction.getDocument(ref)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldReportCount = reportDocument.data()?["reportCount"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve reportCount from snapshot \(reportDocument)"
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }
            
            let newReportCount = oldReportCount + 1
            fields["reportCount"] = newReportCount
            transaction.updateData(fields, forDocument: ref)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            return newReportCount
        }) { (object, error) in
            if let error = error {
                print("Error updating report count: \(error)")
                if error._code == 5 || error._code == -1 {
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
                print("Report count increased to \(object!)")
                    completion(nil)
            }
        }
        }
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
