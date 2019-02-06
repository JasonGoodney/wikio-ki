//
//  OpenedMessageViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/15/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import JGProgressHUD
import FirebaseStorage
import Digger

class OpenedMessageViewController: UIViewController {

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
    
    var photo: UIImage?
    private var player: AVPlayer?
    private var playerController : AVPlayerViewController?
    
    let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()
    

    private lazy var dismissGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(dismissGestureTapped(_:)))
        return gesture
    }()
    
    
    
    init(message: Message, chatWithFriend: ChatWithFriend?) {
        self.message = message
        self.chatWithFriend = chatWithFriend
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        usernameLabel.text = chatWithFriend?.friend.username
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
 
        guard let mediaURL = message?.mediaURL else { return }
        let storagePrefix = "https://firebasestorage.googleapis.com/v0/b/picture-e4799.appspot.com/o/media%2F"
        let uuidLength = UUID().uuidString.count
        
        let temp = String(mediaURL.dropFirst(storagePrefix.count))
        let filename = message?.mediaFilename ?? String(temp.prefix(uuidLength))
        
        let path = DiggerCache.pathsOfDownloadedfiles().filter { (file) -> Bool in
            return file.contains(message?.mediaFilename ?? filename)
        }.first ?? ""
        
        if path != "" && DiggerCache.isFileExist(atPath: path) {

            if self.message?.messageType == .photo {
                self.configureImage(URL(fileURLWithPath: path))

            } else {
                self.configureVideo(URL(fileURLWithPath: path))
            }
            loadingViewController.view.removeGestureRecognizer(dismissGesture)
        }

        else {
            if let thumbnailString = message?.mediaThumbnailURL, let thumbnailURL = URL(string: thumbnailString) {
                imageView.sd_setImage(with: thumbnailURL, completed: nil)
            }

            add(loadingViewController)
            
            Digger.download(mediaURL)
                .progress({ (progresss) in
                    print(progresss.fractionCompleted)
                    
                })
                .speed({ (speed) in
                    print(speed)
                })
                .completion { (result) in
                    
                    switch result {
                    case .success(let url):
                        print(url)
                        if self.message?.messageType == .photo {
                            self.configureImage(url)
                        } else {
                            self.configureVideo(url)
                            
                        }
                        self.loadingViewController.remove()
                        
                    case .failure(let error):
                        print(error)
                        if error._code == 9982 {
                            if self.message?.messageType == .photo {
                                self.configureImage(URL(fileURLWithPath: path))
                            } else {
                                self.configureVideo(URL(string: mediaURL)!)
                                
                            }
                        }
                        self.loadingViewController.hud.dismiss()
                    }
            }
        }

        usernameLabel.addShadow()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupGradientLayer()
        
        
    }
    
    func configureVideo(_ videoURL: URL) {
        let playerItem = CachingPlayerItem(url: videoURL, customFileExtension: "mp4")
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = false
        
        playerController = AVPlayerViewController()
        
        guard player != nil && playerController != nil else {
            return
        }
        playerController!.showsPlaybackControls = false
        
        playerController!.player = player
        addChild(playerController!)
        
        view.addSubview(playerController!.view)
        view.bringSubviewToFront(usernameLabel)
        
        playerController!.view.frame = view.frame
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.player!.currentItem)
        
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
        
        player?.play()
        
    }
    
    func configureImage(_ imageURL: URL) {
        imageView.sd_setImage(with: imageURL)
    }
    
    @objc func dismissGestureTapped(_ recognizer: UITapGestureRecognizer) {
        DispatchQueue.main.async {
            self.dismiss(animated: false)
        }
        
    }
    
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    @objc private func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
                DispatchQueue.main.async {
                    if let parent = self.presentingViewController as? UINavigationController {
                        if let root = parent.viewControllers.last as? MessagesViewController {
                            root.setStatusBar(hidden: false)
                        }
                    }
                }
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    if let parent = self.presentingViewController as? UINavigationController {
                        if let root = parent.viewControllers.last as? MessagesViewController {
                            root.setStatusBar(hidden: true, duration: 0)
                        }
                    }
                }
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }

}

// MARK: - UI
private extension OpenedMessageViewController {
    
    func updateView() {
        view.backgroundColor = .black
        view.addSubviews([imageView, usernameLabel])
        view.addGestureRecognizer(dismissGesture)
        setupConstraints()
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:))))
        
    }
    
    func setupConstraints() {
        imageView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)

        usernameLabel.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 16, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
    }
    
    func setupGradientLayer() {
        gradientLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor]
        gradientLayer.locations = [-0.1, 0.1, 0.9, 1.1]
        view.layer.addSublayer(gradientLayer)
    }
}

