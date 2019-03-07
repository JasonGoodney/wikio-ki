//
//  UserDefaults.swift
//  picture
//
//  Created by Jason Goodney on 2/2/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import Foundation
import Digger
import SDWebImage

extension FileManager {
    
    func clearAllCache() {
        DiggerCache.cleanDownloadFiles()
        DiggerCache.cleanDownloadTempFiles()
        SDWebImageManager.shared().imageCache?.clearMemory()
        SDWebImageManager.shared().imageCache?.clearDisk(onCompletion: nil)
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func save(message: Message, completion: @escaping ErrorCompletion) {
        do {
            let data = try JSONEncoder().encode(message)
            try data.write(to: fileURL(path: message.uid))
            completion(nil)
        } catch let error {
            print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
            completion(error)
        }
    }
    
    func load(fromPath path: String) -> Message? {
        do {
            let data = try Data(contentsOf: fileURL(path: path))
            let message = try JSONDecoder().decode(Message.self, from: data)
            return message
        } catch let error {
            print("🎅🏻\nThere was an error in \(#function): \(error)\n\n\(error.localizedDescription)\n🎄")
        }
        
        return nil
    }
    
    fileprivate func fileURL(path: String = UUID().uuidString) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileName = "\(path).json"
        let documentDirectoryURL = paths[0].appendingPathComponent(fileName)
        return documentDirectoryURL
    }
}
