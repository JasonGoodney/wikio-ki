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
    
    static func saveMediaToStorage(data: Data, thumbnailData: Data, for message: Message, completion: @escaping (Message?, Error?) -> Void) {
        let filename = message.mediaFilename ?? UUID().uuidString
        let thumbnailFilename = UUID().uuidString
        
        let ref = Storage.storage().reference(withPath: Path.media + "\(filename)")
        let thumbnailRef = Storage.storage().reference(withPath: "thumbnails/\(thumbnailFilename)")
        
        let metadata = StorageMetadata()
        let thumbnailMetadata = StorageMetadata()
        thumbnailMetadata.contentType = "image/jpeg"
        
        // Upload Thumbnail
        thumbnailRef.putData(thumbnailData, metadata: thumbnailMetadata) { (_, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            print("Uploaded thumbnail")
            thumbnailRef.downloadURL(completion: { (url, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                let thumbnailURL = url?.absoluteString ?? ""
                
                message.mediaThumbnailURL = thumbnailURL
                
                
                // Upload Media
                if message.messageType == .photo {
                    metadata.contentType = "image/jpeg"
                } else {
                    metadata.contentType = "video/mp4"
                }
                
                ref.putData(data, metadata: metadata) { (_, error) in
                    if let error = error {
                        message.status = .failed
                        completion(nil, error)
                        return
                    }
                    print("Uploaded media")
                    ref.downloadURL(completion: { (url, error) in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        let mediaURL = url?.absoluteString ?? ""
                        
                        message.mediaURL = mediaURL
                        message.status = .delivered
                        
                        completion(message, nil)
                    })
                }
                
            })
        }

        
        
        
    }
}
