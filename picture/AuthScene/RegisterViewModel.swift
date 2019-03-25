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
    var agreedToAgreements: Bool? { didSet { checkFormValidity() } }
    
    func performRegistration(completion: @escaping ErrorCompletion) {
        guard let email = email, let password = password else { return }
        bindableIsRegistering.value = true
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                if error._domain == "FIRAuthErrorDomain" && error._code == 17007 {
                    print("Error creating account: \(error.localizedDescription)")
                    completion(error)
                    return
                } else {
                    print("Error creating account: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
            }

            print("😶 Created account. Email is now taken.")
            

                let filename = UUID().uuidString
                let imageData = self.bindableImage.value?.jpegData(compressionQuality: 0.75) ?? Data()
                let ref = Storage.storage().reference(withPath: "\(StorageService.Path.media)/\(Auth.auth().currentUser!.uid)/\(filename)")
                
                StorageService.shared.upload(data: imageData, withName: filename, atPath: ref, block: { (url) in
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
        
        UserController.shared.currentUser = User(dictionary: docData)
        UserController.shared.currentUser?.profilePhoto = profilePhoto
        
        Firestore.firestore().collection(DatabaseService.Collection.users).document(uid).setData(docData) { (error) in
            if let error = error {
                if error._domain == "FIRAuthErrorDomain" && error._code == 17007 {
                    
                    Auth.auth().currentUser?.delete(completion: { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        print("🛑 There was an error setting users data. Deleted account for so email is not taken.")
                    })
                    completion(error)
                    return
                } else {
                    print("Error creating account: \(error.localizedDescription)")
                    completion(error)
                    return
                }
            }
            
            self.bindableIsRegistering.value = false
            
            let authService = AuthService()
            if let user = Auth.auth().currentUser {
                authService.sendEmailVerifiction(currentUser: user, completion: { (error) in
                    if let error = error {
                        print("\(#function):",error)
                        return
                    }
                    
                    print("👍 Sent verification email to: \(String(describing: user.email))")
                })
            }
            
            let takenUsernameData = ["username": self.username?.lowercased() ?? ""]
            Firestore.firestore().collection(DatabaseService.Collection.takenUsernames).addDocument(data: takenUsernameData) { (error) in
                if let error = error {
                    print("\(#function):",error)
                    completion(error)
                    return
                }
                print("👍 Taken username data set")
                completion(nil)
            }
        }
    }
    
    private func checkFormValidity() {
        guard let username = username, let email = email,
            let password = password, let agreed = agreedToAgreements else {
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
                    && agreed
                
                self.bindableIsFormValid.value = isFormValid
            } else {
                isValidUsername = true
                let isFormValid =
                    isValidUsername
                        && AuthValidation.isValidEmail(email)
                        && AuthValidation.isValidPassword(password)
                        && self.profilePhoto != nil
                    && agreed
                
                self.bindableIsFormValid.value = isFormValid
            }
        }
    }
    
}
