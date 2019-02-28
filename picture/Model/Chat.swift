//
//  Chat.swift
//  picture
//
//  Created by Jason Goodney on 12/30/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

typealias UID = String

class Chat {
    
    let uid: UID
    let memberUids: [UID]
    var lastMessageSent: String
    var lastMessageSentType: MessageType
    var lastChatUpdateTimestamp: TimeInterval
    var lastSenderUid: UID
//    {
//        didSet {
//            let sentToUid = memberUids.first(where: { $0 != lastSenderUid })!
//            let unreadCount = unread?[sentToUid] ?? 0
//            unread?[sentToUid] = unreadCount + 1
//        }
//    }
    var isOpened: Bool
//    {
//        didSet {
//            if isOpened {
//                let openedByUid = memberUids.first(where: { $0 != lastSenderUid })!
//                let unreadCount = unread?[openedByUid]!.count
//                unread?[openedByUid] = unreadCount! > 0 ? unreadCount! - 1 : 0
//            }
//        }
//    }
    var isNewFriendship: Bool
    var areFriends: Bool
    var areMutualBestFriends: Bool
    var unread: [UID: Bool]?
    
    var isSending: Bool
    var status: MessageStatus
    
    var latestMessage: Message?
    var currentUserUnreads: [Message] = []
    var chatUid: String {
        guard memberUids.count == 2 else { return "" }
        return "\(min(memberUids[0], memberUids[1]))_\(max(memberUids[0], memberUids[1]))"
    }
    
    enum Keys {
        static let uid = "uid"
        static let memberUids = "memberUids"
        static let lastMessageSent = "lastMessageSent"
        static let lastMessageSentType = "lastMessageSentType"
        static let lastChatUpdateTimestamp = "lastChatUpdateTimestamp"
        static let lastSenderUid = "lastSenderUid"
        static let isOpened = "isOpened"
        static let isNewFriendship = "isNewFriendship"
        static let areFriends = "areFriends"
        static let areMutualBestFriends = "areMutualBestFriends"
        static let unread = "unread"
        static let isSending = "isSending"
        static let status = "status"
     
    }
    
    init(dictionary: [String: Any]) {
        self.uid = dictionary[Keys.uid] as? String ?? ""
        self.memberUids = dictionary[Keys.memberUids] as? [String] ?? []
        self.lastMessageSent = dictionary[Keys.lastMessageSent] as? String ?? ""
        self.lastChatUpdateTimestamp = dictionary[Keys.lastChatUpdateTimestamp] as? TimeInterval ?? 0
        self.lastSenderUid = dictionary[Keys.lastSenderUid] as? String ?? ""
        self.isOpened = dictionary[Keys.isOpened] as? Bool ?? false
        self.isNewFriendship = dictionary[Keys.isNewFriendship] as? Bool ?? false
        self.areFriends = dictionary[Keys.areFriends] as? Bool ?? false
        self.areMutualBestFriends = dictionary[Keys.areMutualBestFriends] as? Bool ?? false
        self.unread = dictionary[Keys.unread] as? [UID: Bool] ?? [:]
        self.isSending = dictionary[Keys.isSending] as? Bool ?? false
        
        
        if dictionary[Keys.lastMessageSentType] as? String == MessageType.photo.databaseValue() {
            self.lastMessageSentType = .photo
        } else if dictionary[Keys.lastMessageSentType] as? String == MessageType.video.databaseValue() {
            self.lastMessageSentType = .video
        } else {
            self.lastMessageSentType = .none
        }
        
        self.status = .none
        
        if let statusString = dictionary[Keys.status] as? String {
            if statusString == MessageStatus.sending.databaseValue() {
                self.status = .sending
            } else if statusString == MessageStatus.delivered.databaseValue() {
                self.status = .delivered
            } else if statusString == MessageStatus.failed.databaseValue() {
                self.status = .failed
            } else if statusString == MessageStatus.opened.databaseValue() {
                self.status = .opened
            }
        }
    }
    
    init(uid: String = UUID().uuidString, memberUids: [String], lastMessageSent: String, lastMessageSentType: MessageType = .none,
         lastChatUpdateTimestamp: TimeInterval = Date().timeIntervalSince1970, lastSenderUid: String, isOpened: Bool = false, isNewFriendship: Bool = true, areFriends: Bool = true, areMutualBestFriends: Bool = false, isSending: Bool = false, status: MessageStatus = .none) {
        self.uid = uid
        self.memberUids = memberUids
        self.lastMessageSent = lastMessageSent
        self.lastMessageSentType = lastMessageSentType
        self.lastChatUpdateTimestamp = lastChatUpdateTimestamp
        self.lastSenderUid = lastSenderUid
        self.isOpened = isOpened
        self.isNewFriendship = isNewFriendship
        self.areFriends = areFriends
        self.areMutualBestFriends = areMutualBestFriends
        self.isSending = isSending
        self.status = status
    }
    
    func dictionary() -> [String: Any] {
        let dict: [String: Any] = [
            Keys.uid: uid,
            Keys.lastMessageSent: lastMessageSent,
            Keys.lastMessageSentType: lastMessageSentType.databaseValue(),
            Keys.lastChatUpdateTimestamp: lastChatUpdateTimestamp,
            Keys.lastSenderUid: lastSenderUid,
            Keys.isOpened: isOpened,
            Keys.memberUids: memberUids,
            Keys.isNewFriendship: isNewFriendship,
            Keys.areFriends: areFriends,
            Keys.areMutualBestFriends: areMutualBestFriends,
            Keys.unread: unread,
            Keys.isSending: isSending,
            Keys.status: status.databaseValue(),
        ]
        
        return dict
    }
    
    static func chatUid(for currentUser: User, and friend: User) -> String {
        let uid = "\(min(currentUser.uid, friend.uid))_\(max(currentUser.uid, friend.uid))"
        return uid
    }
    
    static func chatUid(for userUid: String, and friendUid: String) -> String {
        let uid = "\(min(userUid, friendUid))_\(max(userUid, friendUid))"
        return uid
    }

}

extension Chat: Equatable, Hashable {
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    var hashValue: Int {
        return uid.hashValue ^ lastSenderUid.hashValue ^ lastChatUpdateTimestamp.hashValue
    }
}
