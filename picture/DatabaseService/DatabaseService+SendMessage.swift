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
        saveChatsCollection(chat) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            self.saveUserChatsCollection(forChatMembersIn: chat) { (error) in
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
        
        saveChatsCollection(chat) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            self.saveUserChatsCollection(forChatMembersIn: chat) { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                self.saveMessagesCollection(message, in: chat) { (error) in
                    if let error = error {
                        print(error)
                        completion(error)
                        return
                    }
                    print("Saved Message")
                    completion(nil)
                }
            }
        }
    }
    
    func update(_ messsage: Message, in chatUid: String, withFields fields: [String: Any], completion: @escaping ErrorCompletion) {
        Firestore.firestore().collection(Collection.messages).document(chatUid).updateData(fields) { (error) in
            if let error = error {
                print(error)
                return
            }
        }
    }
    
    func opened(_ message: Message, in chat: Chat, completion: @escaping ErrorCompletion) {
        let chatUid = Chat.chatUid(for: chat.memberUids[0], and: chat.memberUids[1])
        
        // Update Chat
        let chatField: [String: Any] = [
                Chat.Keys.isOpened: true,
                Chat.Keys.lastChatUpdateTimestamp: Date().timeIntervalSince1970
        ]
        Firestore.firestore().collection(Collection.chats).document(chatUid).updateData(chatField) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Updated chat recent message to opened")
        }
        
        // Update message
        let messageField = ["\(message.uid).\(Message.Keys.isOpened)": true]
        Firestore.firestore().collection(Collection.messages).document(chatUid).updateData(messageField) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Updated message to opened")
        }
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
        let docData = [chat.chatUid: true]
        
        chat.memberUids.forEach { (memberUid) in
            Firestore.firestore().collection(Collection.userChats).document(memberUid).setData(docData, merge: true, completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("Save chatUid to \(memberUid)'s chats")
                completion(nil)
            })
        }
        
    }
}
