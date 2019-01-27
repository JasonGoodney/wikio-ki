//
//  SendMessage.swift
//  picture
//
//  Created by Jason Goodney on 1/23/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

extension DatabaseService {
    
    func sendMessage(from currentUser: User, to friend: User, chat: Chat, caption: String?, messageType: MessageType, mediaData: Data?, thumbnailData: Data?, completion: @escaping (Error?) -> Void) {
        
        let message = Message(senderUid: currentUser.uid, user: currentUser, caption: caption, messageType: messageType)
        
        message.status = .sending
        
        let chatUid = "\(min(currentUser.uid, friend.uid))_\(max(currentUser.uid, friend.uid))"
        print("chatUID: \(chatUid)")
        
        chat.isOpened = false
        chat.lastMessageSent = message.uid
        chat.lastSenderUid = currentUser.uid
        chat.isNewFriendship = false
        chat.isSending = true
        chat.status = .sending
        chat.lastChatUpdateTimestamp = Date().timeIntervalSince1970
        chat.lastMessageSentType = message.messageType
        
        // If Begin
        if let data = mediaData, let thumbnailData = thumbnailData {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let dbs = DatabaseService()
            dbs.save(message, in: chat, completion: { (error) in
                if let error = error {
                    completion(error)
                    return
                }
                print("Sent message from \(currentUser.username) to \(friend.username)")
                                
                StorageService.saveMediaToStorage(data: data, thumbnailData: thumbnailData, for: message) { (messageWithMedia, error) in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    guard let message = messageWithMedia else { return }
                    
                    let fields: [String: Any] = [
                        Message.Keys.status: message.status.databaseValue(),
                        Message.Keys.mediaURL: message.mediaURL,
                        Message.Keys.mediaThumbnailURL: message.mediaThumbnailURL,
                        Message.Keys.timestamp: Date().timeIntervalSince1970
                    ]
                    
                    dbs.update(message, in: chatUid, withFields: fields, completion: { (error) in
                        if let error = error {
                            completion(error)
                            return
                        }
                       chat.status = .delivered
                        dbs.updateDocument(Firestore.firestore().collection(DatabaseService.Collection.chats).document(chatUid), withFields: [
                            Chat.Keys.isSending: false,
                            Chat.Keys.status: chat.status.databaseValue(),
                            Chat.Keys.lastChatUpdateTimestamp: Date().timeIntervalSince1970
                            ], completion: { (error) in
                                if let error = error {
                                    completion(error)
                                    return
                                }
                                print("Everything uploaded and set")
                                completion(nil)
                        })
                        
                    })
                    
                }
            })
        } else {
            print("No image data?")
            return
        }
    }
}
