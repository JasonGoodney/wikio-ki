//
//  Chat.swift
//  picture
//
//  Created by Jason Goodney on 12/30/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Chat {
    
    let uid: String
    let memberUids: [String]
    var lastMessageSent: String
    var lastChatUpdateTimestamp: TimeInterval
    var lastSenderUid: String {
        didSet {
            let sentToUid = memberUids.first(where: { $0 != lastSenderUid })!
            let unreadCount = unread?[sentToUid] ?? 0
            unread?[sentToUid] = unreadCount + 1
        }
    }
    var isOpened: Bool {
        didSet {
            if isOpened {
            let openedByUid = memberUids.first(where: { $0 != lastSenderUid })!
            let unreadCount = unread?[openedByUid]
            unread?[openedByUid] = unreadCount! > 0 ? unreadCount! - 1 : 0
            }
        }
    }
    var isNewFriendship: Bool
    var areFriends: Bool
    var areMutualBestFriends: Bool
    var unread: [String: Int]?
    var isSending: Bool
    
    var chatUid: String {
        guard memberUids.count == 2 else { return "" }
        return "\(min(memberUids[0], memberUids[1]))_\(max(memberUids[0], memberUids[1]))"
    }
    
    enum Keys {
        static let uid = "uid"
        static let memberUids = "memberUids"
        static let lastMessageSent = "lastMessageSent"
        static let lastChatUpdateTimestamp = "lastChatUpdateTimestamp"
        static let lastSenderUid = "lastSenderUid"
        static let isOpened = "isOpened"
        static let isNewFriendship = "isNewFriendship"
        static let areFriends = "areFriends"
        static let areMutualBestFriends = "areMutualBestFriends"
        static let unread = "unread"
        static let isSending = "isSending"
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
        self.unread = dictionary[Keys.unread] as? [String: Int] ?? [:]
        self.isSending = dictionary[Keys.isSending] as? Bool ?? false
    }
    
    init(uid: String = UUID().uuidString, memberUids: [String], lastMessageSent: String,
         lastChatUpdateTimestamp: TimeInterval = Date().timeIntervalSince1970, lastSenderUid: String, isOpened: Bool = false, isNewFriendship: Bool = true, areFriends: Bool = true, areMutualBestFriends: Bool = false, isSending: Bool = false) {
        self.uid = uid
        self.memberUids = memberUids
        self.lastMessageSent = lastMessageSent
        self.lastChatUpdateTimestamp = lastChatUpdateTimestamp
        self.lastSenderUid = lastSenderUid
        self.isOpened = isOpened
        self.isNewFriendship = isNewFriendship
        self.areFriends = areFriends
        self.areMutualBestFriends = areMutualBestFriends
        self.isSending = isSending
    }
    
    func dictionary() -> [String: Any] {
        let dict: [String: Any] = [
            Keys.uid: uid,
            Keys.lastMessageSent: lastMessageSent,
            Keys.lastChatUpdateTimestamp: lastChatUpdateTimestamp,
            Keys.lastSenderUid: lastSenderUid,
            Keys.isOpened: isOpened,
            Keys.memberUids: memberUids,
            Keys.isNewFriendship: isNewFriendship,
            Keys.areFriends: areFriends,
            Keys.areMutualBestFriends: areMutualBestFriends,
            Keys.unread: unread,
            Keys.isSending: isSending
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
