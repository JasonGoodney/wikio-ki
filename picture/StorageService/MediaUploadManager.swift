//
//  MediaUploadManager.swift
//  picture
//
//  Created by Jason Goodney on 2/1/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseAuth

class MediaUploadManager {
    static var urlSessionIdentifier = "mediaUploadsFromMainApp"  // Should be changed in app extensions.
    static let urlSession: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: MediaUploadManager.urlSessionIdentifier)
        configuration.sessionSendsLaunchEvents = false
        configuration.sharedContainerIdentifier = "my-suite-name"
        return URLSession(configuration: configuration)
    }()
    
    // ...
    
    // Example upload URL: https://firebasestorage.googleapis.com/v0/b/my-bucket-name/o?name=user-photos/someUserId/ios/photoKey.jpg
    func startUpload(fileUrl: URL, contentType: String, uploadUrl: URL) {
        Auth.auth().currentUser?.getIDToken() { token, error in
            if let error = error {
                print("ID token retrieval error: \(error.localizedDescription)")
                return
            }
            guard let token = token else {
                print("No token.")
                return
            }
            
            var urlRequest = URLRequest(url: uploadUrl)
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
            urlRequest.httpMethod = "POST"
            let uploadTask = MediaUploadManager.urlSession.uploadTask(with: urlRequest, fromFile: fileUrl)
            uploadTask.resume()
        }
    }
}
