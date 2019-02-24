//
//  PreViewController.swift
//  ARStories
//
//  Created by Antony Raphel on 05/10/17.
//

import UIKit
import AVFoundation
import AVKit
import CoreMedia
import Digger
import FirebaseFirestore

class PreViewController: UIViewController {
    private var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)

    var videoView: UIView = {
        let view = UIView()
        return view
    }()
    var imagePreview: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    let dataSource = MediaViewerDataSource()
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = dataSource
        view.prefetchDataSource = dataSource
        view.delegate = self
        view.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.reuseIdentifier)
        view.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        view.isPagingEnabled = true
        return view
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.addShadow()
        return label
    }()
    
    var chatWithFriend: ChatWithFriend? {
        didSet {
            guard let items = chatWithFriend?.chat.currentUserUnreads else {
                print("problem with unreads queue")
                return
            }
            dataSource.items = items
            self.items = items
            usernameLabel.text = chatWithFriend?.friend.username
        }
    }
    private var pageIndex : Int = 0
    private var items: [Message] = []

    
    private lazy var progressBar: SegmentedProgressBar = {
        let bar = SegmentedProgressBar(numberOfSegments: items.count, duration: 0)
        bar.topColor = UIColor.white
        bar.bottomColor = UIColor.white.withAlphaComponent(0.35)
        bar.padding = 2
        bar.isPaused = true
        bar.currentAnimationIndex = 0
        bar.duration = getDuration(at: 0)
        bar.addShadow()
        return bar
    }()
    
    var player: AVPlayer!
    let loader = ImageLoader()
    
    var statusBarHidden = false
    
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        
        for message in items {
            if message.tempCachedURL != nil {
                return
            } else if let path = DiggerCache.pathsOfDownloadedfiles().first(where: { $0.contains(message.mediaFilename!) }) {
                print("Cached: \(path)")
                message.tempCachedURL = URL(fileURLWithPath: path)
            } else {
                
                Digger.download(message.mediaURL!).completion { (result) in
                    switch result {
                    case .success(let url):
                        print("Downloaded: \(url)")
                        message.tempCachedURL = url
                    case .failure(let error):
                        print("Error downloading url")
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: 0.8) {
            self.view.transform = .identity
        }
        
        setStatusBar(hidden: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.progressBar.startAnimation()
        }
        
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.main.async {
            self.progressBar.currentAnimationIndex = 0
            self.progressBar.cancel()
            self.progressBar.isPaused = true
            self.resetPlayer()
        }
    }

    func dismiss() {
        dismiss(animated: true) {
            let dbs = DatabaseService()
            let openedMessages = self.items.filter({ $0.isOpened })

            guard var unreads = self.chatWithFriend?.chat.currentUserUnreads else {
                fatalError("No unread field")
            }

            for i in 0 ..< openedMessages.count {
                let message = openedMessages[i]

                dbs.delete(message, forUser: UserController.shared.currentUser!, inChat: self.chatWithFriend!.chat, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("Deleted opened message: \(message.uid)")

                    if unreads.indices.contains(i) {
                        unreads.remove(at: i)
                    }
                })
            }




            guard let chat = self.chatWithFriend?.chat else { return }
            let docRef = Firestore.firestore().collection(DatabaseService.Collection.chats).document(chat.chatUid)
            
            chat.status = .opened
            
            var fields: [String: Any] = [Chat.Keys.isOpened: true,
                                         Chat.Keys.lastChatUpdateTimestamp: Date().timeIntervalSince1970,
                                         Chat.Keys.status: chat.status.databaseValue()]
            
            if self.items.filter({ $0.isOpened == false }).isEmpty {
                let key = "unread.\(UserController.shared.currentUser!.uid)"
                fields[key] = false
            }


            dbs.updateData(docRef, withFields: fields, completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("Updated \(chat.chatUid) chat")
            })
            
        }
    }
    
    var currentIndex = 0
    @objc func handlePrevious(_ sender: UITapGestureRecognizer) {
        if currentIndex <= 0 {
            return
        }      
        currentIndex -= 1
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
        progressBar.rewind()
    }
    
    @objc func handleNext(_ sender: UITapGestureRecognizer) {
        if !items.indices.contains(currentIndex + 1) {
            return
        }
        
        currentIndex += 1
        let indexPath = IndexPath(item: currentIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .right, animated: false)
        progressBar.skip()

    }
    
    // MARK: Private func
    @objc fileprivate func playerItemDidReachEnd(_ notification: Notification) {
        if self.player != nil {
            self.player!.seek(to: CMTime.zero)
            self.player!.play()
        }
    }
    
    private func getDuration(at index: Int) -> TimeInterval {
        var retVal: TimeInterval = 5.0
        if items[index].messageType == .photo {
            retVal = 5.0
        } else {
            
            guard let url = NSURL(string: items[index].mediaURL!) as URL? else { return retVal }
            let asset = AVAsset(url: url)
            let duration = asset.duration
            retVal = CMTimeGetSeconds(duration)
        }
        return retVal
    }
    
    private func resetPlayer() {
        if player != nil {
            player.pause()
            player.replaceCurrentItem(with: nil)
            player = nil
        }
    }
    
    func setStatusBar(hidden: Bool, duration: TimeInterval = 0.25) {

        let statusBarWindow = UIApplication.shared.value(forKey: "statusBarWindow") as? UIWindow
        UIView.animate(withDuration: 0) {
            statusBarWindow?.alpha = hidden ? 0.0 : 1.0
        }
    }
    
    //MARK: - Button actions
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        resetPlayer()
    }
    
    @objc private func dismissPanGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == UIGestureRecognizer.State.began {
            initialTouchPoint = touchPoint
        } else if sender.state == UIGestureRecognizer.State.changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
            
                self.progressBar.alpha = 0
                self.usernameLabel.alpha = 0
                
            }
        } else if sender.state == UIGestureRecognizer.State.ended || sender.state == UIGestureRecognizer.State.cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                DispatchQueue.main.async {
                    self.dismiss()
                    self.setStatusBar(hidden: false)
                }
            } else {
                DispatchQueue.main.async {
                    self.setStatusBar(hidden: true)

                }
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                    
                    self.progressBar.alpha = 1
                    self.usernameLabel.alpha = 1
                })
            }
        }
    }
}

extension PreViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let message = items[indexPath.row]
        
        if let videoCell = cell as? VideoCell {
            videoCell.playFromBeginning()
        }
        
        if !message.isOpened {
            message.isOpened = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return view.frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let videoCell = cell as? VideoCell {
            videoCell.pause()
        }
    }
    
}

// MARK: - UI
private extension PreViewController {
    func setupLayout() {
        let frame = self.view.frame
        let leftWidth = frame.width * 0.35
        let rightWidth = frame.width * 0.65
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: leftWidth, height: frame.height))
        leftView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handlePrevious)))
        let rightView = UIView(frame: CGRect(x: view.frame.maxX * 0.35, y: 0, width: rightWidth, height: frame.height))
        rightView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleNext)))
        
        view.addSubviews([collectionView, leftView, rightView, usernameLabel, progressBar])

        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        usernameLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        
        progressBar.anchor(top: nil, leading: usernameLabel.leadingAnchor, bottom: usernameLabel.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 4, right: 16), size: .init(width: 0, height: 2))
        progressBar.addShadow()
        
        view.backgroundColor = .black
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dismissPanGestureRecognizerHandler(_:))))
    }
}



// frKOhvebFho:APA91bEK2mNWBEzW9K3pDQAGAgTU4JIhUXuCVj1GddKPp5ThgjAGjllsy9kPct-qpeKduZQ47lT3HRLo_1nv8XxLBc4NQfF4-fW1EGEgCFfpKiG1t8Sd1q4vZgJrHU2bVFgtVX7ebAbj

//frKOhvebFho:APA91bEK2mNWBEzW9K3pDQAGAgTU4JIhUXuCVj1GddKPp5ThgjAGjllsy9kPct-qpeKduZQ47lT3HRLo_1nv8XxLBc4NQfF4-fW1EGEgCFfpKiG1t8Sd1q4vZgJrHU2bVFgtVX7ebAbj
