//
//  StorageService+StoreMedia.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseStorage

extension StorageService {
    
    static func saveMediaToStorage(data: Data, for message: Message, completion: @escaping (Message?, Error?) -> Void) {
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: Path.media + "\(filename)")
        let metadata = StorageMetadata()
        
        if message.messageType == .photo {
            metadata.contentType = "image/jpeg"
        } else {
            metadata.contentType = "video/mp4"
        }
        
        ref.putData(data, metadata: metadata) { (_, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            ref.downloadURL(completion: { (url, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                let mediaURL = url?.absoluteString ?? ""
                
                message.mediaURL = mediaURL
                completion(message, nil)
//                MessageController.shared.messages.append(message)
//                self.dismiss(animated: false, completion: nil)
//                self.presentingViewController?.dismiss(animated: false) {
//                    DispatchQueue.main.async {
//
//                        message.status = .delivered
//                    }
//                }
//                self.saveInfoToFirestore(message: message, completion: completion)
            })
        }
    }
}
