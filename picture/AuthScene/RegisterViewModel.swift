//
//  RegisterViewModel.swift
//  picture
//
//  Created by Jason Goodney on 12/21/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import JGProgressHUD

typealias ErrorCompletion = (Error?) -> ()

class RegisterViewModel {
    
    var bindableIsRegistering = Bindable<Bool>()
    var bindableIsFormValid = Bindable<Bool>()
    var bindableImage = Bindable<UIImage>()
    
    var profilePhoto: UIImage? { didSet { checkFormValidity() } }
    var username: String? { didSet { checkFormValidity() } }
    var email: String? { didSet { checkFormValidity() } }
    var password: String? { didSet { checkFormValidity() } }
    
    func performRegistration(completion: @escaping ErrorCompletion) {
        guard let email = email, let password = password else { return }
        bindableIsRegistering.value = true
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                completion(error)
                return
            }
            
            let filename = UUID().uuidString
            let imageData = self.bindableImage.value?.jpegData(compressionQuality: 0.75) ?? Data()
            let ref = Storage.storage().reference(withPath: "\(StorageService.Path.media)/\(Auth.auth().currentUser!.uid)/\(filename)")
            StorageService.shared.upload(data: imageData, withName: filename, atPath: ref, block: { (url) in
                self.bindableIsRegistering.value = false
                let imageUrl = url?.absoluteString ?? ""
                self.saveInfoToFirestore(imageUrl: imageUrl, completion: completion)
            })

        }
    }
    
    private func saveImageToFirebase(completion: @escaping ErrorCompletion) {
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/images/\(filename)")
        let imageData = self.bindableImage.value?.jpegData(compressionQuality: 0.75) ?? Data()
        ref.putData(imageData, metadata: nil) { (_, error) in
            if let error = error {
                completion(error)
                return
            }
            
            ref.downloadURL(completion: { (url, error) in
                if let error = error {
                    completion(error)
                    return
                }
                self.bindableIsRegistering.value = false
                let imageUrl = url?.absoluteString ?? ""
                self.saveInfoToFirestore(imageUrl: imageUrl, completion: completion)
            })
        }
    }
    
    private func saveInfoToFirestore(imageUrl: String = "", completion: @escaping ErrorCompletion) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        guard let fcmToken = Messaging.messaging().fcmToken else { return }
        
        let docData = [
            "username": username?.lowercased() ?? "",
            "uid": uid,
            "profilePhotoUrl": imageUrl,
            "email": email?.lowercased() ?? "",
            "fcmToken": fcmToken
        ]
        Firestore.firestore().collection(DatabaseService.Collection.users).document(uid).setData(docData) { (error) in
            if let error = error {
                Auth.auth().currentUser?.delete(completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("There was an error. Deleting account.")
                })
                completion(error)
                return
            }
            
            let authService = AuthService()
            if let user = Auth.auth().currentUser {
                authService.sendEmailVerifiction(currentUser: user, completion: { (error) in
                    if let error = error {
                        Auth.auth().currentUser?.delete(completion: { (error) in
                            if let error = error {
                                print(error)
                                return
                            }
                            print("There was an error. Deleting account.")
                        })
                        print(error)
                        return
                    }
                    
                    print("Sent verification email to: \(user.email)")
                })
            }
            
            let takenUsernameData = ["username": self.username?.lowercased() ?? ""]
            Firestore.firestore().collection(DatabaseService.Collection.takenUsernames).addDocument(data: takenUsernameData) { (error) in
                if let error = error {
                    completion(error)
                    return
                }
                print("saved info to firebase")
                completion(nil)
            }
        }
    }
    
    
    
    private func checkFormValidity() {
        guard let username = username, let email = email, let password = password else {
            bindableIsFormValid.value = false
            return
        }
        
        AuthValidation.isValidUsername(username) { (error) in
            var isValidUsername = false
            if let _ = error {
                let isFormValid =
                    isValidUsername
                    && AuthValidation.isValidEmail(email)
                    && AuthValidation.isValidPassword(password)
                    && self.profilePhoto != nil
                
                self.bindableIsFormValid.value = isFormValid
            } else {
                isValidUsername = true
                let isFormValid =
                    isValidUsername
                        && AuthValidation.isValidEmail(email)
                        && AuthValidation.isValidPassword(password)
                        && self.profilePhoto != nil
                
                self.bindableIsFormValid.value = isFormValid
            }
        }
    }
    
}
