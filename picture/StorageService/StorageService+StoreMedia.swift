//
//  StorageService+StoreMedia.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseStorage

struct CachableMessage: Cachable, Codable {
    
    let fileName: String
    let value: Message
}

extension StorageService {
    
    static func saveMediaToStorage(data: Data, thumbnailData: Data, for message: Message, completion: @escaping (Message?, Error?) -> Void) {
        let filename = message.mediaFilename ?? UUID().uuidString
        let thumbnailFilename = UUID().uuidString
        
        let ref = Storage.storage().reference(withPath: "\(Path.media)/\(UserController.shared.currentUser!.uid)/\(filename)")
        let thumbnailRef = Storage.storage().reference(withPath: "thumbnails/\(thumbnailFilename)")
        
        let mediaMetadata = StorageMetadata()
        let thumbnailMetadata = StorageMetadata()
        thumbnailMetadata.contentType = "image/jpeg"
        
        // Upload Media
        if message.messageType == .photo {
            mediaMetadata.contentType = "image/jpeg"
        } else {
            mediaMetadata.contentType = "video/mp4"
        }
        
        let mediaUploadTask = ref.putData(data, metadata: mediaMetadata) { (metadata, error) in
            if let error = error {
                message.status = .failed
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
                message.status = .delivered
                
                completion(message, nil)
            })
        }
        
        
        // Listen for state changes, errors, and completion of the upload.
        mediaUploadTask.observe(.resume) { snapshot in
            // Upload resumed, also fires when the upload starts
            print("Upload started")
        }
        
        mediaUploadTask.observe(.pause) { snapshot in
            // Upload paused
            print("Upload paused")
        }
        
        mediaUploadTask.observe(.progress) { snapshot in
            // Upload reported progress
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            
            print("Upload: \(percentComplete.rounded())%")
            if UIApplication.shared.isBackground {
                message.mediaData = data
                FileManager.default.save(message: message, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("Saved message \(message.uid) to disk")
                    return
                })

            }
        }
        
        mediaUploadTask.observe(.success) { snapshot in
            // Upload completed successfully
            print("Upload successful")
        }
        
        mediaUploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error {
                switch (StorageErrorCode(rawValue: error._code)!) {
                case .objectNotFound:
                    // File doesn't exist
                    print("Object not found \(error)")
                    break
                case .unauthorized:
                    // User doesn't have permission to access file
                    print("User doesn't have permission to access file \(error)")
                    break
                case .cancelled:
                    // User canceled the upload
                    print("User canceled the upload \(error)")
                    break
                    
                    /* ... */
                    
                case .unknown:
                    // Unknown error occurred, inspect the server response
                    break
                default:
                    // A separate error occurred. This is a good place to retry the upload.
                    break
                }
            }
        }
        
    }
    
//    static func saveMediaToStorage(data: Data, thumbnailData: Data, for message: Message, completion: @escaping (Message?, Error?) -> Void) {
//        let filename = message.mediaFilename ?? UUID().uuidString
//        let thumbnailFilename = UUID().uuidString
//
//        let ref = Storage.storage().reference(withPath: Path.media + "\(filename)")
//        let thumbnailRef = Storage.storage().reference(withPath: "thumbnails/\(thumbnailFilename)")
//
//        let mediaMetadata = StorageMetadata()
//        let thumbnailMetadata = StorageMetadata()
//        thumbnailMetadata.contentType = "image/jpeg"
//
//        URLSessionConfiguration.default.isDiscretionary = true
//
//        let storage = Storage.storage().reference(forURL: "gs://picture-e4799.appspot.com/media")
//
//
//        // Upload Thumbnail
//        var uploadTask = thumbnailRef.putData(thumbnailData, metadata: thumbnailMetadata) { (_, error) in
//            if let error = error {
//                completion(nil, error)
//                return
//            }
//
//            print("Uploaded thumbnail")
//            thumbnailRef.downloadURL(completion: { (url, error) in
//                if let error = error {
//                    completion(nil, error)
//                    return
//                }
//                let thumbnailURL = url?.absoluteString ?? ""
//
//                message.mediaThumbnailURL = thumbnailURL
//
//
//                // Upload Media
//                if message.messageType == .photo {
//                    mediaMetadata.contentType = "image/jpeg"
//                } else {
//                    mediaMetadata.contentType = "video/mp4"
//                }
//
//                let mediaUploadTask = ref.putData(data, metadata: mediaMetadata) { (metadata, error) in
//                    if let error = error {
//                        message.status = .failed
//                        completion(nil, error)
//                        return
//                    }
//                    print("Uploaded media data size:", Double((metadata?.size)!) / BinarySize.MB)
//                    print("Uploaded media")
//                    ref.downloadURL(completion: { (url, error) in
//                        if let error = error {
//                            completion(nil, error)
//                            return
//                        }
//                        let mediaURL = url?.absoluteString ?? ""
//
//                        message.mediaURL = mediaURL
//                        message.status = .delivered
//
//                        completion(message, nil)
//                    })
//                }
//
//
//                // Listen for state changes, errors, and completion of the upload.
//                mediaUploadTask.observe(.resume) { snapshot in
//                    // Upload resumed, also fires when the upload starts
//                    print("Upload started")
//                }
//
//                mediaUploadTask.observe(.pause) { snapshot in
//                    // Upload paused
//                    print("Upload paused")
//                }
//
//                mediaUploadTask.observe(.progress) { snapshot in
//                    // Upload reported progress
//                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//                        / Double(snapshot.progress!.totalUnitCount)
//
//                    print("Upload: \(percentComplete.rounded())%")
//                }
//
//                mediaUploadTask.observe(.success) { snapshot in
//                    // Upload completed successfully
//                    print("Upload successful")
//                }
//
//                mediaUploadTask.observe(.failure) { snapshot in
//                    if let error = snapshot.error {
//                        switch (StorageErrorCode(rawValue: error._code)!) {
//                        case .objectNotFound:
//                            // File doesn't exist
//                            print("Object not found \(error)")
//                            break
//                        case .unauthorized:
//                            // User doesn't have permission to access file
//                            print("User doesn't have permission to access file \(error)")
//                            break
//                        case .cancelled:
//                            // User canceled the upload
//                            print("User canceled the upload \(error)")
//                            break
//
//                            /* ... */
//
//                        case .unknown:
//                            // Unknown error occurred, inspect the server response
//                            break
//                        default:
//                            // A separate error occurred. This is a good place to retry the upload.
//                            break
//                        }
//                    }
//                }
//
//            })
//        }
//
//        // Listen for state changes, errors, and completion of the upload.
//        uploadTask.observe(.resume) { snapshot in
//            // Upload resumed, also fires when the upload starts
//            print("Upload started")
//        }
//
//        uploadTask.observe(.pause) { snapshot in
//            // Upload paused
//            print("Upload pause")
//        }
//
//        uploadTask.observe(.progress) { snapshot in
//            // Upload reported progress
//            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
//                / Double(snapshot.progress!.totalUnitCount)
//            print("Upload: \(percentComplete.rounded())%")
//        }
//
//        uploadTask.observe(.success) { snapshot in
//            // Upload completed successfully
//            print("Upload successful")
//        }
//
//        uploadTask.observe(.failure) { snapshot in
//            if let error = snapshot.error {
//                switch (StorageErrorCode(rawValue: error._code)!) {
//                case .objectNotFound:
//                    // File doesn't exist
//                    print("Object not found \(error)")
//                    break
//                case .unauthorized:
//                    // User doesn't have permission to access file
//                    print("User doesn't have permission to access file \(error)")
//                    break
//                case .cancelled:
//                    // User canceled the upload
//                    print("User canceled the upload \(error)")
//                    break
//
//                    /* ... */
//
//                case .unknown:
//                    // Unknown error occurred, inspect the server response
//                    break
//                default:
//                    // A separate error occurred. This is a good place to retry the upload.
//                    break
//                }
//            }
//        }
//
//    }
}
