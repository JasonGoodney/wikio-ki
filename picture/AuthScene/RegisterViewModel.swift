//
//  RegisterViewModel.swift
//  picture
//
//  Created by Jason Goodney on 12/21/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import Firebase

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
            
            self.saveImageToFirebase(completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("Saved image to firebase")
                completion(nil)
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
        let docData = [
            "username": username?.lowercased() ?? "",
            "uid": uid,
            "profilePhotoUrl": imageUrl,
            "email": email?.lowercased() ?? ""
        ]
        Firestore.firestore().collection(DatabaseService.Collection.users).document(uid).setData(docData) { (error) in
            if let error = error {
                completion(error)
                return
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
