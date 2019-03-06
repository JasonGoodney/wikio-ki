//
//  DatabaseService+Friend.swift
//  picture
//
//  Created by Jason Goodney on 1/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension DatabaseService {
    
    // MARK: - Send Request
    func sendFriendRequest(to user: User, completion: @escaping (AddFriendState?, Error?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return }
        let addFriendState: AddFriendState = .requested
//        let friendRequestData: [String: Any] = ["requestedBy": currentUser.uid]
        let friendRequestData: [String: Any] = [currentUser.uid: true]
        Firestore.firestore().collection(DatabaseService.Collection.users)
            .document(user.uid).collection(DatabaseService.Collection.friendRequests)
            .addDocument(data: friendRequestData) { (error) in
                if let error = error {
                    print(error)
                    completion(nil, error)
                    return
                }
                
                print("\(user.username) has a friend request from \(currentUser.username)")
                completion(addFriendState, nil)
        }
        
        let sentRequestData: [String: Any] = ["sentTo": user.uid]
        Firestore.firestore().collection(DatabaseService.Collection.users)
            .document(currentUser.uid).collection(DatabaseService.Collection.sentRequests)
            .document(user.uid).setData(sentRequestData, merge: true) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("\(currentUser.username) sent request to \(user.username)")

                completion(addFriendState, nil)
        }
    }
    
    // MARK: - Accept Request
    func acceptFriendRequest(from user: User, completion: @escaping ErrorCompletion) {

        guard let currentUser = UserController.shared.currentUser else { return }
        
        let chat = Chat(memberUids: [currentUser.uid, user.uid], lastMessageSent: "", lastSenderUid: "")
        chat.unread = [currentUser.uid: false, user.uid: false]
        
        let dbs = DatabaseService()
        dbs.createInitialChat(chat) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            currentUser.addFriend(user)
            user.addFriend(currentUser)
            
            let currentUserUserChat = Firestore.firestore().collection(Collection.userChats).document(currentUser.uid)
            let friendUserChat = Firestore.firestore().collection(Collection.userChats).document(user.uid)
            self.changeUserChat(isActive: true, between: currentUser, andFriend: user, changeBoth: true)
//            dbs.updateDocument(currentUserUserChat, withFields: [chat.chatUid : true], completion: { (error) in
//                if let error = error {
//                    print(error)
//                    completion(error)
//                    return
//                }
//                print("\(currentUser.username)'s userChat is")
//                dbs.updateDocument(friendUserChat, withFields: [chat.chatUid : true], completion: { (error) in
//                    if let error = error {
//                        print(error)
//                        completion(error)
//                        return
//                    }
                    self.removeFriendRequest(to: UserController.shared.currentUser!, from: user) { (error) in
                        if let error = error {
                            print(error)
                            completion(error)
                            return
                        }
                        
                        self.removeSentRequest(from: user, to: UserController.shared.currentUser!) { (error) in
                            if let error = error {
                                print(error)
                                completion(error)
                                return
                            }
                            
                            completion(nil)
                        }
                    }
                    
//                })
//
//            })
        
            
            
            
        }
    }
    
    func removeFriendRequest(to: User, from: User, completion: @escaping ErrorCompletion) {
//        Firestore.firestore().collection(DatabaseService.Collection.users).document(to.uid).collection(DatabaseService.Collection.friendRequests).document(from.uid).delete { (error) in
//            if let error = error {
//                print(error)
//                completion(error)
//                return
//            }
//            print("Removed request to \(to.uid)")
//            completion(nil)
//        }
        Firestore.firestore().collection(DatabaseService.Collection.users).document(to.uid).collection(DatabaseService.Collection.friendRequests).getDocuments { (snapshot, error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            let friendRequestToDelete = docs.first(where: { (doc) -> Bool in
                let friendRequest = doc.data() as! [String: Bool]
                return friendRequest.keys.first! == from.uid
            })
            
            friendRequestToDelete?.reference.delete(completion: { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                print("Removed request to \(to.uid)")
                completion(nil)
            })
        }
    }
    
    func removeSentRequest(from: User, to: User, completion: @escaping ErrorCompletion) {
        Firestore.firestore()
            .collection(DatabaseService.Collection.users).document(from.uid)
            .collection(DatabaseService.Collection.sentRequests).document(to.uid).delete { (error) in
                if let error = error {
                    print(error)
                    completion(error)
                    return
                }
                print("removed sent request from \(from.uid)")
                completion(nil)
        }
    }
    
    // MARK: - Fetches
    func fetchBestFriends(for userUid: String = (UserController.shared.currentUser?.uid)!, completion: @escaping ([String]?, Error?) -> Void) {
        Firestore.firestore()
            .collection(Collection.users).document(userUid)
            .collection(Collection.friends).whereField("isBestFriend", isEqualTo: true).getDocuments { (snapshot, error) in
                if let error = error {
                    print(error)
                    completion(nil, error)
                    return
                }
                
                let docs = snapshot?.documents
                var bestFriends: [String] = []
                docs?.forEach({ (doc) in
                    let dict = doc.data()
                    guard let uid = dict.keys.first(where: { $0 != "isBestFriend" }) else { return }
                    bestFriends.append(uid)
                    completion(bestFriends, nil)
                })
        }
    }
    
    // MARK: - Actions
    func removeFriend(_ friend: User, completion: @escaping ErrorCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return }
        UserController.shared.currentUser?.friendsUids.remove(friend.uid)
        UserController.shared.allChatsWithFriends.removeAll(where: { $0.friend.uid == friend.uid })
        
        let chatUid = Chat.chatUid(for: UserController.shared.currentUser!, and: friend)
        
        if let unreads = UserController.shared.unreads[friend.uid], !unreads.isEmpty {
            UIApplication.shared.decrementBadgeNumber()
        }
        
        // Delete the userChat references
        Firestore.firestore().collection(Collection.userChats).document(currentUser.uid)
            .updateData([chatUid: FieldValue.delete()]) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("\(chatUid) is removed from \(currentUser.username)'s userchats")
                
                Firestore.firestore().collection(Collection.userChats).document(friend.uid)
                    .updateData([chatUid: FieldValue.delete()]) { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        print("\(chatUid) is removed from \(friend.username)'s userchats")
                        
                        // Delete the friend from the current users friends list
                        Firestore.firestore().collection(Collection.users).document(currentUser.uid).collection(Collection.friends).document(friend.uid).delete { (error) in
                            if let error = error {
                                print(error)
                                completion(error)
                                return
                            }
                            print("removed \(friend.username) from \(currentUser.username)'s friend list")
                            
                            // Delete the current user from the friends friends list
                            Firestore.firestore().collection(Collection.users).document(friend.uid).collection(Collection.friends).document(currentUser.uid).delete { (error) in
                                if let error = error {
                                    print(error)
                                    completion(error)
                                    return
                                }
                                print("removed \(currentUser.username) from \(friend.username)'s friend list")
                                
                                // Delete the chat between the two users
                                Firestore.firestore().collection(Collection.chats).document(chatUid).delete { (error) in
                                    if let error = error {
                                        print(error)
                                        completion(error)
                                        return
                                    }
                                    print("removed \(chatUid) chat")
                                    
                                
                                    
                                    completion(nil)
                                }
                            }
                        }
                }
        }

    }

    func changeUserChat(isActive: Bool, between currentUser: User, andFriend friend: User, changeBoth: Bool = false) {
        let chatUid = Chat.chatUid(for: currentUser, and: friend)
        
        Firestore.firestore().collection(Collection.userChats).document(currentUser.uid).updateData([chatUid: isActive]) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("\(currentUser.username) is\(isActive ? "" : " not ")active with \(friend.username)")
        }
        
        if changeBoth {
            Firestore.firestore().collection(Collection.userChats).document(friend.uid).updateData([chatUid: isActive]) { (error) in
                if let error = error {
                    print(error)
                    return
                }

                print("\(friend.username) is\(isActive ? "" : " not ")active with \(currentUser.username)")
            }
        }
        

    }
}
