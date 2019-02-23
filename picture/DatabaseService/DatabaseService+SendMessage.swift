//
//  DatabaseService+SendMessage.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

 extension DatabaseService {
    
    func createInitialChat(_ chat: Chat,  completion: @escaping ErrorCompletion) {
        
            saveUserChatsCollection(forChatMembersIn: chat) { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                
                self.saveChatsCollection(chat) { (error) in
                    if let error = error {
                        print(error)
                        completion(error)
                        return
                    }
                    print("Created initial chat")
                    completion(nil)
            }
        }
    }
    
    func save(_ message: Message, in chat: Chat, completion: @escaping ErrorCompletion) {
        
//        if let sentToUid = chat.members.first(where: { $0 != chat.lastSenderUid }), let unreadDict = chat.unread {
//            let unreadCount = unreadDict[sentToUid]! + 1
//            chat.unread?[sentToUid] = unreadCount
//        }
        
        saveChatsCollection(chat) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
//            self.saveUserChatsCollection(forChatMembersIn: chat) { (error) in
//                if let error = error {
//                    print(error)
//                    completion(error)
//                    return
//                }
                self.saveMessagesCollectionInChats(message, in: chat) { (error) in
                    if let error = error {
                        print(error)
                        completion(error)
                        return
                    }
                    print("Saved Message")
                    Firestore.firestore().collection(Collection.users).document(UserController.shared.currentUser!.uid).collection(Collection.sentMessages).addDocument(data: message.dictionary(), completion: { (error) in
                        if let error = error {
                            print(error)
                            completion(error)
                            return
                        }
                        completion(nil)
                    })
                }
//            }
        }
    }
    
    func update(_ messsage: Message, in chatUid: String, withFields fields: [String: Any], completion: @escaping ErrorCompletion) {
        DatabaseService.messagesReference(forPath: chatUid).document(messsage.uid).updateData(fields) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            completion(nil)
    }
//        Firestore.firestore().collection(Collection.messages).document(chatUid).updateData(fields) { (error) in
//            if let error = error {
//                print(error)
//                return
//            }
//        }
    }
    
    func opened(_ message: Message, in chat: Chat, completion: @escaping ErrorCompletion) {
        let chatUid = Chat.chatUid(for: chat.memberUids[0], and: chat.memberUids[1])
        
        // Chat fields to update
        let chatField: [String: Any] = [
            Chat.Keys.isOpened: chat.isOpened,
            Chat.Keys.lastChatUpdateTimestamp: Date().timeIntervalSince1970,
            Chat.Keys.unread: chat.unread
        ]

        // Update Chat
        Firestore.firestore().collection(Collection.chats).document(chatUid).updateData(chatField) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            print("Updated chat recent message to opened")
            
            // Update message
            let messageField = [Message.Keys.isOpened: true]
            DatabaseService.messagesReference(forPath: chatUid).document(message.uid).updateData(messageField) { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                print("Updated message to opened")
                completion(nil)
            }
        }
    }
    
    func delete(_ message: Message, in chat: Chat, completion: @escaping ErrorCompletion) {
        Firestore.firestore().collection(Collection.chats).document(chat.chatUid).collection(Collection.messages).document(message.uid).delete(completion: completion)
    }
    
    func delete(_ message: Message, forUser user: User, inChat chat: Chat, completion: @escaping ErrorCompletion) {
    Firestore.firestore().collection(Collection.chats).document(chat.chatUid).collection(user.uid).document(message.uid).delete(completion: completion)
    }
}

private extension DatabaseService {
    
    private func saveChatsCollection(_ chat: Chat, completion: @escaping ErrorCompletion) {
        Firestore.firestore().collection(Collection.chats).document(chat.chatUid).setData(chat.dictionary()) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Saved chat \(chat.chatUid) to collection")
            completion(nil)
        }
    }
    
    private func saveMessagesCollectionInChats(_ message: Message, in chat: Chat, completion: @escaping ErrorCompletion) {
        Firestore.firestore().collection(Collection.chats).document(chat.chatUid).collection(Collection.messages).document(message.uid).setData(message.dictionary(), merge: true) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Added message \(message.uid) to chat collection \(chat.chatUid)")
            completion(nil)
        }
    }
    
    private func saveMessagesCollection(_ message: Message, in chat: Chat, completion: @escaping ErrorCompletion) {
        Firestore.firestore().collection(Collection.messages).document(chat.chatUid).setData([message.uid: message.dictionary()], merge: true) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Added message \(message.uid) to chat collection \(chat.chatUid)")
            completion(nil)
        }
    }
    
    private func saveUserChatsCollection(forChatMembersIn chat: Chat, completion: @escaping ErrorCompletion) {
        let docData = [chat.chatUid: false]
        
        chat.memberUids.forEach { (memberUid) in
            Firestore.firestore().collection(Collection.userChats).document(memberUid).setData(docData, merge: true, completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("Save chatUid to \(memberUid)'s chats, but not yet friends")
                completion(nil)
            })
        }
        
    }
}
