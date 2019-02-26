//
//  SendToPreviewView.swift
//  picture
//
//  Created by Jason Goodney on 2/25/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import AVKit

class SendToPreviewView: UIView {
    
    // MARK: - Properties
    private var image: UIImage? = nil
    private var player: AVPlayer? = nil

    // MARK: - Views
    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    private let videoView = UIView()
    
    init(image: UIImage) {
        super.init(frame: .zero)
        
        configure(image)
    }
    
    init(videoURL: URL) {
        super.init(frame: .zero)
        
        self.configure(videoURL)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func configure(_ image: UIImage) {
        addSubview(imageView)
        imageView.image = image
        imageView.anchor(top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor)
    }
    
    private func configure(_ videoURL: URL) {
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
        
        playFromBeginning()
        
    }
    
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        playFromBeginning()
    }
    
    private func playFromBeginning() {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    private func pause() {
        if self.player != nil {
            player?.pause()
        }
    }
    
}
