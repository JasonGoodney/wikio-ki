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
import SDWebImage

extension DatabaseService {
    
    func send(_ message: Message, from currentUser: User, to friend: User, chat: Chat, mediaData: Data?, thumbnailData: Data?, completion: @escaping (Error?) -> Void) {
        

        let chatUid = chat.chatUid
        print("chatUID: \(chatUid)")
        
        
        // If Begin
        if let data = mediaData, let thumbnailData = thumbnailData {

            
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
                        Message.Keys.mediaURL: message.mediaURL as Any,
                        Message.Keys.mediaThumbnailURL: message.mediaThumbnailURL as Any,
                        Message.Keys.timestamp: message.timestamp as Any
                    ]
                    
                    dbs.update(message, in: chatUid, withFields: fields, completion: { (error) in
                        if let error = error {
                            completion(error)
                            return
                        }
                        

                        chat.unread?[friend.uid] = true
                        chat.status = .delivered
                        chat.isOpened = false
                        chat.lastMessageSent = message.uid
                        chat.lastSenderUid = currentUser.uid
                        chat.isNewFriendship = false
                        chat.isSending = false
                        //chat.status = .sending
                        chat.lastChatUpdateTimestamp = Date().timeIntervalSince1970
                        chat.lastMessageSentType = message.messageType
                        
                        dbs.updateDocument(Firestore.firestore().collection(DatabaseService.Collection.chats).document(chatUid), withFields: chat.dictionary(), completion: { (error) in
                            if let error = error {
                                completion(error)
                                return
                            }
                            let friendsUnreadCollection = Firestore.firestore().collection(DatabaseService.Collection.chats).document(chatUid).collection(friend.uid)
                            friendsUnreadCollection.document(message.uid).setData(message.dictionary(), completion: { (error) in
                                if let error = error {
                                    completion(error)
                                    return
                                }
                                    print("Everything uploaded and set")
                                    completion(nil)
                                
                            })
                            
                        })
                        
                    })
                    
                }
            })
        } else {
            print("No image data?")
            return
        }
    }
    
    func sendMessage(_ message: Message, from currentUser: User, to friend: User, chat: Chat, completion: @escaping (Error?) -> Void) {
        
        
        let chatUid = chat.chatUid
        print("chatUID: \(chatUid)")
        
            let dbs = DatabaseService()
            dbs.save(message, in: chat, completion: { (error) in
                if let error = error {
                    completion(error)
                    return
                }
                print("Sent message from \(currentUser.username) to \(friend.username)")

                let fields: [String: Any] = [
                    Message.Keys.status: message.status.databaseValue(),
                    Message.Keys.mediaURL: message.mediaURL as Any,
                    Message.Keys.mediaThumbnailURL: message.mediaThumbnailURL as Any,
                    Message.Keys.timestamp: message.timestamp as Any
                ]
                
                dbs.update(message, in: chatUid, withFields: fields, completion: { (error) in
                    if let error = error {
                        completion(error)
                        return
                    }
                    
                    
                    chat.unread?[friend.uid] = true
                    chat.status = .delivered
                    chat.isOpened = false
                    chat.lastMessageSent = message.uid
                    chat.lastSenderUid = currentUser.uid
                    chat.isNewFriendship = false
                    chat.isSending = false
                    //chat.status = .sending
                    chat.lastChatUpdateTimestamp = Date().timeIntervalSince1970
                    chat.lastMessageSentType = message.messageType
                    
                    dbs.updateDocument(Firestore.firestore().collection(DatabaseService.Collection.chats).document(chatUid), withFields: chat.dictionary(), completion: { (error) in
                        if let error = error {
                            completion(error)
                            return
                        }
                        let friendsUnreadCollection = Firestore.firestore().collection(DatabaseService.Collection.chats).document(chatUid).collection(friend.uid)
                        friendsUnreadCollection.document(message.uid).setData(message.dictionary(), completion: { (error) in
                            if let error = error {
                                completion(error)
                                return
                            }
                            print("Everything uploaded and set")
                            completion(nil)
                            
                        })
                        
                    })
                })
        })
    }
}
