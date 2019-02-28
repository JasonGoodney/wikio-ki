//
//  VideoCell.swift
//  picture
//
//  Created by Jason Goodney on 2/7/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import JGProgressHUD
import FirebaseStorage
import Digger

class VideoCell: UICollectionViewCell, ReuseIdentifiable {

    
    private var message: Message?
    private var chatWithFriend: ChatWithFriend?
    
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
    
    private let loadingViewController = LoadingViewController()
    
    private let gradientLayer = CAGradientLayer()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    var videoView: UIView = {
        let view = UIView()
        return view
    }()
    
    var player: AVPlayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let mediaViews = [videoView]
        addSubviews(mediaViews)
        mediaViews.forEach({
            $0.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func configureVideo(_ videoURL: URL) {
        let playerItem = CachingPlayerItem(url: videoURL, customFileExtension: "mp4")
//        guard let downloadURL = NSURL(string: message.mediaURL!) as? URL else { return }
        self.player = AVPlayer(playerItem: playerItem)
        
        player?.automaticallyWaitsToMinimizeStalling = false
        let videoLayer = AVPlayerLayer(player: self.player)
        videoLayer.frame = bounds
        videoLayer.videoGravity = .resizeAspect
        self.videoView.layer.addSublayer(videoLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player!.currentItem)
        
        // Allow background audio to continue to play
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, mode: .default, options: [])
            } else {
            }
        } catch let error as NSError {
            print(error)
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print(error)
        }
        
        //player?.play()
        
    }
    
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        playFromBeginning()
    }
    
    func playFromBeginning() {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    func pause() {
        if self.player != nil {
            player?.pause()
        }
    }
}
