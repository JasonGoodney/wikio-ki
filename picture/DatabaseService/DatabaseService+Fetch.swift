//
//  DatabaseService+Fetch.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension DatabaseService {
    
    func fetchUser(for uid: String, completion: @escaping (User?, Error?) -> Void) {
        Firestore.firestore().collection(Collection.users).document(uid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            
            guard let dict = snapshot?.data() else { return }
            let user = User(dictionary: dict)
            completion(user, nil)
        }
    }
    
    func fetchUserChats(for user: User, completion: @escaping ([String]?, Error?) -> Void) {
        Firestore.firestore().collection(Collection.userChats).document(user.uid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            var userChats: [String] = []
            
            guard let docs = snapshot?.data() as? [String: Bool] else {
                completion([], nil)
                return
            }
            
            for doc in docs {
                if doc.value == true {
                    userChats.append(doc.key)
                }
            }
            
            completion(userChats, nil)
        }
    }
    
    func fetchChat(_ chatUid: String, completion: @escaping (Chat?, Error?) -> Void) {
        Firestore.firestore().collection(Collection.chats).document(chatUid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            
            guard let data = snapshot?.data() else { return }
            let chat = Chat(dictionary: data)
            completion(chat, nil)
        }
    }
    
    func fetchFriend(in chat: Chat, completion: @escaping (User?, Error?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return }
        guard let friendUid = chat.memberUids.first(where: { $0 != currentUser.uid }) else { return }
        Firestore.firestore().collection(Collection.users).document(friendUid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            guard let data = snapshot?.data() else { return }
            let friend = User(dictionary: data)
            completion(friend, nil)
        }
    }
    
    func fetchChats(completion: @escaping ([Chat]?, Error?) -> Void) {
        Firestore.firestore().collection(Collection.chats).getDocuments { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            var chats: [Chat] = []
            
            docs.forEach({ (doc) in
                let dict = doc.data()
                let chat = Chat(dictionary: dict)
                chats.append(chat)
            })
            
            completion(chats, nil)
        }
    }
    
    func fetchLatestMessage(in chat: Chat, completion: @escaping (Message?, Error?) -> Void) {
        let chatUid = Chat.chatUid(for: chat.memberUids[0], and: chat.memberUids[1])
        Firestore.firestore().collection(Collection.messages).document(chatUid).getDocument { (snapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            
            guard let data = snapshot?.data() else {
                return
            }
            let dict: [String: Any] = data[chat.lastMessageSent] as! [String : Any]
            let message = Message(dictionary: dict)
            completion(message, nil)
        }
    }
    
    
    
    func fetchMessagesInChat(withFriend friend: User, completion: @escaping ([Message]?, Error?) -> Void) {
        MessageController.shared.messages = []
        
        guard let currentUser = UserController.shared.currentUser else { return }
        let chatUid = "\(min(currentUser.uid, friend.uid))_\(max(currentUser.uid, friend.uid))"
    
        #warning("App is only fetching messages from the mast 24 hours and unopened message")
        
        let secondsInADay: TimeInterval = 86400
        let currentTime = Date().timeIntervalSince1970
        let last24Hours = currentTime - secondsInADay
        
        let allMessagesRef = Firestore.firestore().collection(Collection.chats).document(chatUid).collection(Collection.messages)
        let messagesLast24HoursRef = Firestore.firestore().collection(Collection.chats).document(chatUid).collection(Collection.messages)
            .whereField(Message.Keys.timestamp, isGreaterThanOrEqualTo: last24Hours)
        let messagesNotOpenedRef = Firestore.firestore().collection(Collection.chats).document(chatUid).collection(Collection.messages)
            .whereField(Message.Keys.isOpened, isEqualTo: false)
        
        messagesNotOpenedRef.getDocuments(completion: { (notOpenedQuerySnapshot, error) in
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
              
            guard var queryDocs = notOpenedQuerySnapshot?.documents else { return }
            
            //var queryDocsSet: Set<QueryDocumentSnapshot> = Set(queryDocs)
                
            messagesLast24HoursRef.getDocuments(completion: { (last24HoursQuerySnapshot, error) in
                    if let error = error {
                        print(error)
                        completion(nil, error)
                        return
                    }
                    
                    var messageDocs: [QueryDocumentSnapshot] = []
                    
                    if last24HoursQuerySnapshot?.documents != nil {
//                        queryDocsSet = queryDocsSet.union(last24HoursQuerySnapshot!.documents)
                        //docs = Array(Set(isOpenedQuerySnapshot!.documents))
                        
                        queryDocs += (last24HoursQuerySnapshot?.documents)!
                    }
                    
                    let queryDocsSet = Set(queryDocs)
                
                let messagesSet: Set<Message> = Set(queryDocs.map({ (snapshot) -> Message? in
                    return Message(dictionary: snapshot.data())
                })) as! Set<Message>
                
                    messagesSet.forEach({ (message) in
                        //let message = Message(dictionary: doc.data())
                        let index = MessageController.shared.messages.insertionIndexOf(elem: message, isOrderedBefore: { (a, b) -> Bool in
                            return a.timestamp < b.timestamp
                        })
                        MessageController.shared.messages.insert(message, at: index)
                    })
                
                
                    completion(MessageController.shared.messages, nil)
            })
        })
    }

    func fetchChat(withFriend friend: User, completion: @escaping (Chat?, Error?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return }
        let chatUid = Chat.chatUid(for: currentUser, and: friend)
        Firestore.firestore().collection(Collection.chats).document(chatUid).getDocument { (snapshot, error) in
            
            if let error = error {
                print(error)
                completion(nil, error)
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            let chat = Chat(dictionary: data)
            
            completion(chat, nil)
        }
    }
    
    func fetchTakenUsername(username: String, completion: @escaping (_ isTaken: Bool) -> Void) {
        var takenUsernameListener: ListenerRegistration?
        takenUsernameListener = Firestore.firestore().collection(Collection.takenUsernames).whereField("username", isEqualTo: username).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print(error)
                takenUsernameListener?.remove()
                completion(false)
                return
            }
            guard let usernamesCount = snapshot?.documents.count else { completion(false); return }
            
            if usernamesCount > 0 {
                print("\(username) count = \(usernamesCount)")
                takenUsernameListener?.remove()
                completion(true)
                
            } else {
                takenUsernameListener?.remove()
                completion(false)
            }
        }
        
    }
}
