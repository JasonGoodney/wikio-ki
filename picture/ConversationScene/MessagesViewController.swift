//
//  MessagesViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SwiftyCam
import FirebaseFirestore
import AVKit

class MessagesViewController: UIViewController {
    
    private var newMessageListener: ListenerRegistration?
    var chat: Chat?
    var friend: Friend? {
        didSet {
            configure()
        }
    }
    private let spacing: CGFloat = 5
    private let cellId = MessagesCell.reuseIdentifier
    private var messages: [Message] = []
    
    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.register(MessagesCell.self, forCellWithReuseIdentifier: cellId)
        view.backgroundColor = .white
        view.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 56 + 32, right: 0)
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .black)
        return label
    }()
    
    private lazy var openCameraToolbar: OpenCameraToolbar = {
        let toolbar = OpenCameraToolbar()
        toolbar.openCameraDelegate = self
        let scrollDoubleTap = UITapGestureRecognizer(target: self, action: #selector(scrollToBottom))
        scrollDoubleTap.numberOfTapsRequired = 2
        toolbar.addGestureRecognizer(scrollDoubleTap)
        return toolbar
    }()
    
    private let profileImageButton: ProfileImageButton = {
        let button = ProfileImageButton(height: 32, width: 32)
        return button
    }()
    
    private lazy var sendPhotoButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Test", style: .plain, target: self, action: #selector(sendPhoto))
        return button
    }()
    
    @objc private func sendPhoto() {
        let photo = UIImage(named: "IMG_1536")
        let dbs = DatabaseService()

        let data = photo?.jpegData(compressionQuality: Compression.photoQuality)
        let thumbnailData = photo?.jpegData(compressionQuality: Compression.thumbnailQuality)
        dbs.sendMessage(from: UserController.shared.currentUser!, to: friend!, chat: chat!, caption: nil, messageType: .photo, mediaData: data, thumbnailData: thumbnailData) { (error) in
            if let error = error {
                print(error)
                return
            }
            
            print("Sent photo for testing")
        }
    }
    
    private func fetchReloadMessages() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.collectionView.scrollToItem(at: IndexPath(item: self.messages.count-1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: false)
        }
    }
    
    @objc private func scrollToBottom() {
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: IndexPath(item: self.messages.count-1, section: 0), at: UICollectionView.ScrollPosition.bottom, animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let databaseService = DatabaseService()
        databaseService.fetchMessagesInChat(withFriend: friend!) { (messages, error)  in
            if let error = error {
                print(error)
                return
            }
            guard let messages = messages else { return }
            self.messages = messages
            self.fetchReloadMessages()
        }

        updateView()
        
        if let chatUid = chat?.chatUid {
            newMessageListener = DatabaseService.messagesReference(forPath: chatUid).addSnapshotListener({ (querySnapshot, error) in
                if let error = error {
                    print(error)
                    return
                }
                guard let changes = querySnapshot?.documentChanges else { return }
                
                let pendingWrites = changes.filter({
                    $0.document.metadata.hasPendingWrites
                })
                
                let modifiedDocs = changes.filter({
                    $0.type == .modified
                })
                
                // Sending user local updates
                if pendingWrites.count > 0 {
                    pendingWrites.forEach({ (change) in
                        let pendingMessage = Message(dictionary: change.document.data())
                        self.collectionView.performBatchUpdates({
                            
                            let insertIndexPath = IndexPath(row: self.messages.count, section: 0)
                            
                            let isSender = pendingMessage.senderUid == UserController.shared.currentUser?.uid
                            
                            if isSender {
                                if let reloadIndex = self.messages.firstIndex(where: { $0 == pendingMessage }),
                                    pendingMessage.status == .delivered {
                                    
                                    let reloadIndexPath = IndexPath(row: reloadIndex, section: 0)
                                    self.messages[reloadIndexPath.row] = pendingMessage
                                    let animationsEnabled = UIView.areAnimationsEnabled
                                    UIView.setAnimationsEnabled(false)
                                    self.collectionView.reloadItems(at: [reloadIndexPath])
                                    UIView.setAnimationsEnabled(animationsEnabled)
                                    
                                } else if pendingMessage.status == .sending {
                                    self.messages.append(pendingMessage)
                                    self.collectionView.insertItems(at: [insertIndexPath])
                                    
                                }
                            } else if !isSender && pendingMessage.status == .delivered {
                                if change.type == .modified {
//                                    self.messages.append(pendingMessage)
//                                    self.collectionView.insertItems(at: [insertIndexPath])
                                    guard let reloadIndex = self.messages.firstIndex(where: { $0 == pendingMessage }) else {
                                        print("Index does not exists on pending write 🤷‍♂️")
                                        return
                                    }
                                    let reloadIndexPath = IndexPath(row: reloadIndex, section: 0)
                                    self.messages[reloadIndexPath.row] = pendingMessage
                                    let animationsEnabled = UIView.areAnimationsEnabled
                                    UIView.setAnimationsEnabled(false)
                                    self.collectionView.reloadItems(at: [reloadIndexPath])
                                    UIView.setAnimationsEnabled(animationsEnabled)
                                    
                                } else if change.type == .added {
                                    
                                }
                                
                            }
                        }, completion: nil)

                    })
                  
                    
                }
                // Receiving user updates and sender user updates when receiver opens
                else if modifiedDocs.count > 0 {
                    for change in modifiedDocs {
                        let modifiedMessage = Message(dictionary: change.document.data())
                        self.collectionView.performBatchUpdates({
                            
                            let insertIndexPath = IndexPath(row: self.messages.count, section: 0)
                            
                            let isSender = modifiedMessage.senderUid == UserController.shared.currentUser?.uid

                            if isSender {
                                if let reloadIndex = self.messages.firstIndex(where: { $0 == modifiedMessage }),
                                    modifiedMessage.status == .delivered {
                                    
//                                    self.messages[reloadIndex] = modifiedMessage
//                                    self.collectionView.reloadData()
                                     let reloadIndexPath = IndexPath(row: reloadIndex, section: 0)

                                    self.messages[reloadIndexPath.row] = modifiedMessage
                                    let animationsEnabled = UIView.areAnimationsEnabled
                                    UIView.setAnimationsEnabled(false)
                                    self.collectionView.reloadItems(at: [reloadIndexPath])
                                    UIView.setAnimationsEnabled(animationsEnabled)

                                } else if modifiedMessage.status == .sending {
                                    self.messages.append(modifiedMessage)
                                    self.collectionView.insertItems(at: [insertIndexPath])

                                }
                            } else if !isSender && modifiedMessage.status == .delivered {
                                    self.messages.append(modifiedMessage)
                                    self.collectionView.insertItems(at: [insertIndexPath])
                            }
                        }, completion: nil)

                    }
                }
            })
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = nil
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = nil
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 247, green: 247, blue: 247, alpha: 1)
        
        if let urlString = friend?.profilePhotoUrl, let url = URL(string: urlString) {
            DispatchQueue.main.async {
                self.profileImageButton.sd_setImage(with: url, for: .normal, completed: { (_, _, _, _) in
                    self.profileImageButton.isUserInteractionEnabled = true
                })
            }
        }
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    
        
        if isMovingFromParent {
            newMessageListener?.remove()
        }
    }
    
    @objc func detailsButtonTapped(_ sender: UIBarButtonItem) {
        userDescructionActionSheet { (type) in
            let dbs = DatabaseService()
            guard let friend = self.friend else { return }
            switch type {
            case .bestFriend:
                var fields: [String: Bool] = [:]
                let document = Firestore.firestore().collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid).collection(DatabaseService.Collection.friends).document(friend.uid)
                if friend.isBestFriend {
                    print("Remove as best friend")
                    fields = ["isBestFriend": false]
                    UserController.shared.bestFriendUids.removeAll(where: { $0 == friend.uid })
                    
                } else {
                    print("add as best friend")
                    fields = ["isBestFriend": true]
                    UserController.shared.bestFriendUids.append(friend.uid)
                }
                dbs.updateDocument(document, withFields: fields, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                })
            case .remove:
                dbs.removeFriend(friend, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    print("Removed friend")
                    self.navigationController?.popToRootViewController(animated: true)
                })
            case .block:
                dbs.block(user: friend, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    UserController.shared.blockedUids.append(friend.uid)
                    self.navigationController?.popToRootViewController(animated: true)
                })
            case .report:
                ()
            case .none:
                ()
            }
        }
    }
    
    @objc private func profileImageButtonTapped() {
        guard let friend = friend else { return }
        let profileDetailsViewController = ProfileDetailsViewController(user: friend, isBestFriend: friend.isBestFriend, addFriendState: .accepted)
        navigationController?.pushViewController(profileDetailsViewController, animated: true)
    }
}

// MARK: - UI
private extension MessagesViewController {
    func configure() {
        guard let friend = friend else { return }
        navigationItem.title = friend.username
    }
    func updateView() {
        view.backgroundColor = .white
        view.addSubviews(collectionView, openCameraToolbar)
        setupConstraints()
        setupNavigationBar()
    }
    
    func setupConstraints() {
        collectionView.anchor(view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: openCameraToolbar.topAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)

        openCameraToolbar.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    func setupNavigationBar() {
        titleLabel.text = navigationItem.title
        navigationItem.titleView = titleLabel
        navigationController?.navigationBar.tintColor = .black
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: profileImageButton)
        
        navigationItem.rightBarButtonItem?.customView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageButtonTapped)))
    }
}

extension MessagesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! MessagesCell
        
        let message = messages[indexPath.row]
        
        var sender: User
        
        if message.senderUid == friend?.uid && friend != nil {
            sender = friend!
        } else {
            sender = UserController.shared.currentUser!
        }
        
        cell.configure(with: message, from: sender)
        
        cell.delegate = self
        
        return cell
    }
}

extension MessagesViewController: UICollectionViewDelegate {
    
    func loadMedia(url: URL, completion: @escaping(Bool) -> Void) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? MessagesCell else { return }
        
        let message = messages[indexPath.row]

        if message.status == .sending {
            cell.messageIsSendingWarning()
            return
        }
        
        let viewMessagesVC = OpenedMessageViewController(message: message)
 
        guard let url = URL(string: message.mediaURL!) else { return }
        present(viewMessagesVC, animated: false) {
            DispatchQueue.main.async {
                guard let currentUser = UserController.shared.currentUser, let friend = self.friend else { return }
                if message.senderUid != currentUser.uid, !message.isOpened {
                    message.isOpened = true
                    self.chat?.isOpened = true
                    let dbs = DatabaseService()

                    let chatUid = "\(min(currentUser.uid, friend.uid))_\(max(currentUser.uid, friend.uid))"

                    if let chat = self.chat {
                        dbs.opened(message, in: chat, completion: { (error) in
                            if let error = error {
                                print(error)
                                return
                            }
                            print("Message was opened and firebase was updated")
                        })
                    }
                    //self.collectionView.reloadItems(at: [indexPath])
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MessagesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.width, height: 88)
    }
}

extension MessagesViewController: OpenCameraToolbarDelegate {
    func didTapOpenCameraButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraViewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        cameraViewController.friend = friend
        cameraViewController.chat = chat
        present(cameraViewController, animated: true, completion: nil)
    }
}

extension MessagesViewController: MessageCellDelegate {
    func loadMedia(for cell: MessagesCell, message: Message) {
        
    }
}
