//
//  MediaViewerDataSource.swift
//  picture
//
//  Created by Jason Goodney on 2/8/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import Digger

class MediaViewerDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching {
    
    var items: [Message] = []
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = items[indexPath.row]
        
        guard let url = message.tempCachedURL ?? URL(string: message.mediaURL!) else { return UICollectionViewCell() }
        
        if message.messageType == .photo {
            let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCell.reuseIdentifier, for: indexPath) as! PhotoCell
            photoCell.configurePhoto(url)
            return photoCell
        } else if message.messageType == .video {
            let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.reuseIdentifier, for: indexPath) as! VideoCell
            videoCell.configureVideo(url)
            videoCell.playFromBeginning()
            
            return videoCell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            cacheURL(message: items[indexPath.row])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            print("Cancelled Task")
            DiggerManager.shared.cancelTask(for: items[indexPath.row].mediaURL!)
        }
    }
    
    func cacheURL(message: Message) {
        Digger.download(message.mediaURL!).completion { (result) in
            switch result {
            case .success(let url):
                print("Message: \(message.uid)")
                message.tempCachedURL =  url
            case .failure(let error):
                print(error)
            }
        }
    }
}
