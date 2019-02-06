//
//  Message.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseFirestore

enum MessageStatus: String, Codable {
    case opened
    case delivered
    case received
    case failed
    case sending
    case none
    
    func text() -> String {
        return self.rawValue.capitalized
    }
    
    func databaseValue() -> String {
        return self.rawValue.uppercased()
    }
}

enum MessageType: String, Codable {
    case photo
    case video
    case none
    
    func databaseValue() -> String {
        return self.rawValue.uppercased()
    }
}

class Message: Codable {
    
    let uid: String
    //var user: User?
    let senderUid: String
    var isOpened: Bool
    var status: MessageStatus
    let messageType: MessageType
    let caption: String?
    var mediaURL: String?
    var mediaFilename: String?
    var mediaThumbnailURL: String?
    let timestamp: TimeInterval
    
    var mediaData: Data?
    
    enum Keys {
        static let uid = "uid"
        static let senderUid = "senderUid"
        static let isOpened = "isOpened"
        static let caption = "caption"
        static let mediaURL = "mediaURL"
        static let mediaFilename = "mediaFilename"
        static let timestamp = "timestamp"
        static let messageType = "messageType"
        static let mediaThumbnailURL = "mediaThumbnailURL"
        static let status = "status"
    }
    
    init(dictionary: [String: Any]) {
        self.uid = dictionary[Keys.uid] as? String ?? ""
        self.senderUid = dictionary[Keys.senderUid] as? String ?? ""
        self.isOpened = dictionary[Keys.isOpened] as! Bool
        self.caption = dictionary[Keys.caption] as? String ?? ""
        self.mediaURL = dictionary[Keys.mediaURL] as? String ?? ""
        self.mediaFilename = dictionary[Keys.mediaFilename] as? String ?? ""
        self.mediaThumbnailURL = dictionary[Keys.mediaThumbnailURL] as? String ?? ""
        self.timestamp = dictionary[Keys.timestamp] as? TimeInterval ?? 0
        
        if dictionary[Keys.messageType] as? String == MessageType.photo.databaseValue() {
            self.messageType = .photo
        } else {
            self.messageType = .video
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
        
//        Firestore.firestore().collection(DatabaseService.Collection.users).document(senderUid).getDocument { (snapshot, error) in
//            if let error = error {
//                print(error)
//                return
//            }
//
//            guard let dict = snapshot?.data() else { return }
//            self.user = User(dictionary: dict)
//        }
    }
    
    init(uid: String = UUID().uuidString, senderUid: String,
         caption: String? = nil, mediaURL: String? = nil, mediaFilename: String? = UUID().uuidString, mediaThumbnailURL: String? = nil, timestamp: TimeInterval = Date().timeIntervalSince1970,
         isOpened: Bool = false, status: MessageStatus = .none, messageType: MessageType) {
        self.uid = uid
        self.senderUid = senderUid
//        self.user = user
        self.isOpened = isOpened
        self.status = status
        self.caption = caption
        self.mediaURL = mediaURL
        self.mediaFilename = mediaFilename
        self.timestamp = timestamp
        self.messageType = messageType
        self.mediaThumbnailURL = mediaThumbnailURL
    }
    
    func dictionary() -> [String: Any] {
        var dict: [String: Any] = [
            Keys.uid: uid,
            Keys.senderUid: senderUid,
            Keys.isOpened: isOpened,
            Keys.timestamp: timestamp,
            Keys.status: status.databaseValue(),
            Keys.messageType: messageType.databaseValue()
        ]
        
        if caption != nil {
            dict[Keys.caption] = caption
        }
        
        if mediaURL != nil {
            dict[Keys.mediaURL] = mediaURL
        }
        
        if mediaThumbnailURL != nil {
            dict[Keys.mediaThumbnailURL] = mediaThumbnailURL
        }
        
        if mediaFilename != nil {
            dict[Keys.mediaFilename] = mediaFilename
        }
        
        return dict
    }
    
    // MARK: - Codable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Firebase
        try container.encode(uid, forKey: .uid)
        try container.encode(senderUid, forKey: .senderUid)
        try container.encode(isOpened, forKey: .isOpened)
        try container.encode(caption, forKey: .caption)
        try container.encode(mediaFilename, forKey: .mediaFilename)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(messageType, forKey: .messageType)
        try container.encode(status, forKey: .status)
        
        // Local media data
        try container.encode(mediaData, forKey: .mediaData)
    }
    
    private enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case senderUid = "senderUid"
        case isOpened = "isOpened"
        case caption = "caption"
        case mediaURL = "mediaURL"
        case mediaFilename = "mediaFilename"
        case timestamp = "timestamp"
        case messageType = "messageType"
        case mediaThumbnailURL = "mediaThumbnailURL"
        case status = "status"
        
        case mediaData = "mediaData"
    }
    
    required convenience init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Firebase
        let uid: String = try container.decode(String.self, forKey: .uid)
        let senderUid: String = try container.decode(String.self, forKey: .senderUid)
        let isOpened: Bool = try container.decode(Bool.self, forKey: .isOpened)
        let status: MessageStatus = try container.decode(MessageStatus.self, forKey: .status)
        let messageType: MessageType = try container.decode(MessageType.self, forKey: .messageType)
        let caption: String = try container.decode(String.self, forKey: .caption)
        let mediaFilename: String = try container.decode(String.self, forKey: .mediaFilename)
        let timestamp: TimeInterval = try container.decode(TimeInterval.self, forKey: .timestamp)
        
        self.init(uid: uid, senderUid: senderUid, caption: caption, mediaFilename: mediaFilename, timestamp: timestamp, isOpened: isOpened, status: status, messageType: messageType)
        
        // Local media data
        self.mediaData = try container.decode(Data.self, forKey: .mediaData)
    }
}

extension Message: Equatable, Hashable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    var hashValue: Int {
        return uid.hashValue ^ senderUid.hashValue
    }
}
