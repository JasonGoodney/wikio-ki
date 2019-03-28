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
import FirebaseFunctions

class PreViewController: UIViewController {
    // Firebase Functions
    private lazy var functions = Functions.functions()
    
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
    
    private lazy var flagButton: PopButton = {
        let button = PopButton()
        button.setTitle("•••", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.addShadow()
        button.addTarget(self, action: #selector(flagButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var likeGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLike))
        return gesture
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
        bar.addShadow(opacity: 0.3)
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
    
    deinit {
        print("PreView deinit")
        DiggerManager.shared.cancelAllTasks()
        self.handleDeletingMessages()
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
                        print("Error downloading url: \(error.localizedDescription)")
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
            
            
            print("Dismissed")
        }
    }
    
    var currentIndex = 0
    
    // MARK: - Actions
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
    
    @objc private func handleLike() {
        let message = items[currentIndex]
        if !message.isLiked {
            message.isLiked = true
            let likeImageView = UIImageView(image: #imageLiteral(resourceName: "icons8-like").withRenderingMode(.alwaysTemplate))
            likeImageView.tintColor = Theme.like
            view.addSubview(likeImageView)
            likeImageView.anchorCenterXToSuperview()
            likeImageView.anchorCenterYToSuperview()
            likeImageView.alpha = 0
            UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.2, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                likeImageView.transform = CGAffineTransform(scaleX: 3.0, y: 3.0)
                likeImageView.alpha = 1
            }) { (finished) in
                likeImageView.alpha = 0
                likeImageView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            }
            print("Liked \(items[currentIndex].messageType.databaseValue().lowercased())")
            guard let friend = chatWithFriend?.friend else { return }
            let data = ["friendUid": friend.uid,
                        "likedByUsername": UserController.shared.currentUser!.username,
                        "messageType": message.messageType.databaseValue().lowercased()]
            functions.httpsCallable("observeLike").call(data) { (result, error) in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        let details = error.userInfo[FunctionsErrorDetailsKey]
                    }
                    // ...
                }
            }

        }
    }
    
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
    
    @objc private func flagButtonTapped() {
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(blurEffectView)
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let flagAction = UIAlertAction(title: "Flag", style: .destructive) { (action) in
            print("Handle flagging content")
            if let friend = self.chatWithFriend?.friend {
                let reportVC = UINavigationController(rootViewController: ReportViewController(friend: friend))
                self.setStatusBar(hidden: false)
                self.present(reportVC, animated: true, completion: nil)
            }
            UIView.animate(withDuration: 0.25, animations: {
                blurEffectView.alpha = 0
            }, completion: { (_) in
                blurEffectView.removeFromSuperview()
            })
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            UIView.animate(withDuration: 0.25, animations: {
                blurEffectView.alpha = 0
            }, completion: { (_) in
                blurEffectView.removeFromSuperview()
            })
        }
        alertController.addAction(flagAction)
        alertController.addAction(cancelAction)
        presentAlert(alertController)
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
        
        view.addSubviews([collectionView, leftView, rightView, usernameLabel, progressBar, flagButton])

        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        usernameLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: nil, padding: .init(top: 0, left: 16, bottom: 0, right: 0))
        
        progressBar.anchor(top: nil, leading: usernameLabel.leadingAnchor, bottom: usernameLabel.topAnchor, trailing: flagButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 4, right: 16), size: .init(width: 0, height: 2))
        progressBar.addShadow()
        
        flagButton.anchor(top: nil, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 16))
        flagButton.centerYAnchor.constraint(equalTo: progressBar.centerYAnchor).isActive = true
        
        view.backgroundColor = .black
        
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(dismissPanGestureRecognizerHandler(_:))))
        view.addGestureRecognizer(likeGesture)
    }
}

private extension PreViewController {
    func handleDeletingMessages() {
        let dbs = DatabaseService()
        let openedMessages = self.items.filter({ $0.isOpened })
        
        for i in 0 ..< openedMessages.count {
            let message = openedMessages[i]
            
            dbs.delete(message, forUser: UserController.shared.currentUser!, inChat: self.chatWithFriend!.chat, completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                print("Deleted opened message: \(message.uid)")
            })
        }
        
        guard let chat = self.chatWithFriend?.chat else { return }
        let docRef = Firestore.firestore().collection(DatabaseService.Collection.chats).document(chat.chatUid)
        
        chat.status = .opened
        
        var fields: [String: Any] = [Chat.Keys.isOpened: true,
                                     Chat.Keys.lastChatUpdateTimestamp: Date().timeIntervalSince1970,
                                     Chat.Keys.status: chat.status.databaseValue()]
        
        if self.items.filter({ $0.isOpened == false }).isEmpty {
            chat.unread?[UserController.shared.currentUser!.uid] = false
            
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
