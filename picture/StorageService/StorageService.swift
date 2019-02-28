//
//  StorageService.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseStorage

// Here is the completion block
typealias FileCompletionBlock = () -> Void
var block: FileCompletionBlock?

class StorageService {
    
    enum Path {
        static let images = "images/"
        static let media = "media"
    }
    
    /// Singleton instance
    static let shared: StorageService = StorageService()
    
    /// Path
    let kMediaStorageRef = Storage.storage().reference().child(Path.media)
    
    /// Current uploading task
    var currentUploadTask: StorageUploadTask?
    
    func upload(data: Data,
                withName fileName: String,
                block: @escaping (_ url: URL?) -> Void) {
        
        // Create a reference to the file you want to upload
        let fileRef = kMediaStorageRef.child(fileName)
        
        /// Start uploading
        upload(data: data, withName: fileName, atPath: fileRef) { (url) in
            block(url)
        }
    }
    
    func upload(data: Data,
                withName fileName: String,
                atPath path:StorageReference,
                block: @escaping (_ url: URL?) -> Void) {
        
        // Upload the file to the path
        self.currentUploadTask = path.putData(data, metadata: nil) { (metadata, error) in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                block(nil)
                return
            }
            
            // Metadata contains file metadata such as size, content-type.
            // let size = metadata.size
            // You can also access to download URL after upload.
            path.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    block(nil)
                    return
                }
                block(url)
            }
        }
    }
    
    func cancel() {
        self.currentUploadTask?.cancel()
    }
    
    func startUploading(data: [Data], completion: @escaping FileCompletionBlock) {
        if data.count == 0 {
            completion()
            return;
        }
        
        block = completion
        uploadData(forIndex: 0)
    }
    
    func uploadData(forIndex index:Int) {
        
//        if index < images.count {
//            /// Perform uploading
//            let data = UIImagePNGRepresentation(images[index])!
//            let fileName = String(format: "%@.png", "yourUniqueFileName")
//
//            StorageService.shared.upload(data: data, withName: fileName, block: { (url) in
//                /// After successfully uploading call this method again by increment the **index = index + 1**
//                print(url ?? "Couldn't not upload. You can either check the error or just skip this.")
//                self.uploadImage(forIndex: index + 1)
//            })
//            return;
//        }
//
//        if block != nil {
//            block!()
//        }
    }
    
    func download(mediaURL: String, message: Message, completion: @escaping (URL?, Error?) -> Void) {

        let storagePrefix = "https://firebasestorage.googleapis.com/v0/b/picture-e4799.appspot.com/o/media%2F"
        let uuidLength = UUID().uuidString.count
        
        let temp = String(mediaURL.dropFirst(storagePrefix.count))
        let filename = message.mediaFilename ?? String(temp.prefix(uuidLength))
        
        
        let ref = Storage.storage().reference(withPath: Path.media + filename)
        
        let downloadTask = ref.getData(maxSize: 10 * 1024 * 1024) { (data, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            print("Got Data")
        }
        
        downloadTask.observe(.failure) { (snapshot) in
            guard let errorCode = (snapshot.error as? NSError)?.code else {
                return
            }
            guard let error = StorageErrorCode(rawValue: errorCode) else {
                return
            }
            switch (error) {
            case .objectNotFound:
                // File doesn't exist
                break
            case .unauthorized:
                // User doesn't have permission to access file
                break
            case .cancelled:
                // User cancelled the download
                break
                
                /* ... */
                
            case .unknown:
                // Unknown error occurred, inspect the server response
                break
            default:
                // Another error occurred. This is a good place to retry the download.
                break
            }
            completion(nil, snapshot.error)
        }
        
        downloadTask.observe(.progress) { snapshot in
            // Download reported progress
            let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                / Double(snapshot.progress!.totalUnitCount)
            print("Downloaded: %\(percentComplete)")
        }
        
        downloadTask.observe(.success) { snapshot in
            completion(URL(string: mediaURL), nil)
        }

    }
}
