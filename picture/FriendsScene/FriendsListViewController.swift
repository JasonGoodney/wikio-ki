//
//  FriendsListViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/13/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import SwiftyCam
import FirebaseAuth
import FirebaseFirestore
import JGProgressHUD
import SDWebImage

extension Collection {
    
    /// Get at index object
    ///
    /// - Parameter index: Index of object
    /// - Returns: Element at index or nil
    func get(at index: Index) -> Iterator.Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
}

class FriendsListViewController: UIViewController {
    
    // Firebase Listeners
    var friendRequestListener: ListenerRegistration?
    var friendshipChangedListener: ListenerRegistration?
    var blockedUserListener: ListenerRegistration?
    var chatUpdateListener: ListenerRegistration?
    var userChatsListener: ListenerRegistration?
    
    private let sectionHeaders = ["BEST FRIENDS", "RECENTS", "FRIENDS", "No friends :/\n\nAdd some :)"]
    private let sectionHeaderHeight: CGFloat = 50
    private let goToAddFriendCellHeight: CGFloat = 120
    private let goToAddFriendSectionHeight: CGFloat = 80
    
    // MARK: - Subviews
    private var hud = JGProgressHUD(style: .dark)
    
    private let noFriendsLabel: UILabel = {
        let label = UILabel()
        label.text = "No friends :/\n\nAdd some :)"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = WKTheme.darkGray
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(FriendsListCell.self, forCellReuseIdentifier: FriendsListCell.reuseIdentifier)
        view.register(GoToAddFriendCell.self, forCellReuseIdentifier: GoToAddFriendCell.reuseIdentifier)
        view.separatorStyle = .none
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(handleRefreshFriends), for: UIControl.Event.valueChanged)
        return view
    }()
    
    private let titleLabel = NavigationTitleLabel(title: "Wikio Ki")
    
    private lazy var addFriendButton: PopButton = {
        let button = PopButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        button.setImage(#imageLiteral(resourceName: "icons8-plus_math").withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(addFriendButtonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 16
        return button
    }()
    
    private let profileImageButton: ProfileImageButton = {
        let button = ProfileImageButton(height: 32, width: 32)
        return button
    }()
    
    private lazy var doubleTapRefresh: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleRefreshFriends))
        gesture.numberOfTapsRequired = 2
        return gesture
    }()
    
    deinit {
        friendRequestListener?.remove()
        friendshipChangedListener?.remove()
        chatUpdateListener?.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = AppDelegate()
        appDelegate.attemptRegisterForNotifications(UIApplication.shared)
        
        updateView()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        UserController.shared.fetchCurrentUser { (success) in
            if success {
                
                if let image = UserController.shared.currentUser?.profilePhoto {
                    self.profileImageButton.setImage(image, for: .normal)
                    self.profileImageButton.isUserInteractionEnabled = true
                } else if let urlString = UserController.shared.currentUser?.profilePhotoUrl, let url = URL(string: urlString) {
                    DispatchQueue.main.async {
                        self.profileImageButton.sd_setImage(with: url, for: .normal, placeholderImage: placeholderProfileImage, options: [], completed: { (_, _, _, _) in
                            self.profileImageButton.isUserInteractionEnabled = true
                        })
                    }
                }
                
                self.friendRequestListener = Firestore.firestore()
                    .collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid)
                    .collection(DatabaseService.Collection.friendRequests).addSnapshotListener { (snapshot, error) in
                        
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        guard let docChanges = snapshot?.documentChanges else { return }
                        
                        // New requests are ones that have not been seen ([uid: true]) in Firebase
                        let newRequests = docChanges.filter({ (change) -> Bool in
                            guard let data = change.document.data() as? [String: Bool] else { return false }
                            return data.values.first == true
                        })
                        
                        if newRequests.count == 0 {
                            self.addFriendButton.setImage(#imageLiteral(resourceName: "icons8-plus_math").withRenderingMode(.alwaysTemplate), for: .normal)
                            self.addFriendButton.tintColor = .black
                            return
                        }
                        
                        newRequests.forEach({ (diff) in
                            if diff.type == .added {
                                if self.addFriendButton.imageView?.image != #imageLiteral(resourceName: "icons8-add") {
                                    self.addFriendButton.pop()
                                    self.addFriendButton.setImage(#imageLiteral(resourceName: "icons8-add"), for: .normal)
                                    self.addFriendButton.tintColor = WKTheme.buttonBlue
                                }
                                return
                            } else if diff.type == .removed {
                                self.addFriendButton.setImage(#imageLiteral(resourceName: "icons8-plus_math").withRenderingMode(.alwaysTemplate), for: .normal)
                                self.addFriendButton.tintColor = .black
                                return
                            }
                        })
                }
                
                self.userChatsListener = Firestore.firestore().collection(DatabaseService.Collection.userChats).document(UserController.shared.currentUser!.uid).addSnapshotListener({ (snapshot, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    guard let doc = snapshot else {
                        print("No userchats doc")
                        return
                    }
                    let source = doc.metadata.hasPendingWrites ? "Local" : "Server"
                    if doc.metadata.hasPendingWrites {
                        print(source)
                        self.reloadData()
                    } else {
                        print(source)
                        self.handleRefreshFriends()
                    }
                })
                
                let value = UserController.shared.currentUser?.uid as Any
                
                self.chatUpdateListener = Firestore.firestore().collection(DatabaseService.Collection.chats)
                    .whereField(Chat.Keys.memberUids, arrayContains: value)
                    .addSnapshotListener({ (querySnapshot, error) in
                    
                        guard let snapshot = querySnapshot else {
                            print("Error fetching documents: \(error!)")
                            return
                        }
                        
                            let modifiedDocs = snapshot.documentChanges.filter({
                                $0.type == .modified
                            })
                            
                            let pendingWrites = snapshot.documentChanges.filter({
                                $0.document.metadata.hasPendingWrites
                            })
                            
                            if pendingWrites.count > 0 {
                                pendingWrites.forEach({ (change) in
                                    let pendingChat = Chat(dictionary: change.document.data())
                                    
                                    self.tableView.performBatchUpdates({
                                        if let index = UserController.shared.allChatsWithFriends.firstIndex(where: { $0.chat.uid == pendingChat.uid }) {
                                            let beforeRecentsCount = UserController.shared.recentChatsWithFriends.count
                                            UserController.shared.allChatsWithFriends[index].chat = pendingChat
                                            let afterRecentsCount = UserController.shared.recentChatsWithFriends.count
                                            
                                            if beforeRecentsCount < afterRecentsCount {
                                                self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                                            }
                                            //
                                            self.tableView.reloadData()
                                            //
                                        }
                                    }, completion: { (_) in
                                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                    })
                                })
                            }
                        
                                // Receiving user updates and sender user updates when receiver opens
                            else if modifiedDocs.count > 0 {
                                for change in modifiedDocs {
                                    let pendingChat = Chat(dictionary: change.document.data())
                                    self.tableView.performBatchUpdates({

//                                        let insertIndexPath = IndexPath(row: self.messages.count, section: 0)

                                        let isSender = pendingChat.lastSenderUid == UserController.shared.currentUser?.uid

                                        if isSender {
                                            if let index = UserController.shared.allChatsWithFriends.firstIndex(where: { $0.chat.uid == pendingChat.uid }) {
                                                let beforeRecentsCount = UserController.shared.recentChatsWithFriends.count
                                                UserController.shared.allChatsWithFriends[index].chat = pendingChat
                                                let afterRecentsCount = UserController.shared.recentChatsWithFriends.count
                                                
                                                if beforeRecentsCount < afterRecentsCount {
                                                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                                                }
                                                //
                                                self.tableView.reloadData()
                                                //
                                            }
                                        } else if !isSender && !pendingChat.isSending {
                                            if let index = UserController.shared.allChatsWithFriends.firstIndex(where: { $0.chat.uid == pendingChat.uid }) {
                                                let beforeRecentsCount = UserController.shared.recentChatsWithFriends.count
                                                UserController.shared.allChatsWithFriends[index].chat = pendingChat
                                                let afterRecentsCount = UserController.shared.recentChatsWithFriends.count
                                                
                                                if beforeRecentsCount < afterRecentsCount {
                                                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .automatic)
                                                }
                                                //
                                                self.tableView.reloadData()
                                                //
                                            }
                                        }
                                        
                                    }, completion: nil)

                                }
                        }

                        

                })
            }
        }

        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
       
    }
 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectCell()
        
        if let urlString = UserController.shared.currentUser?.profilePhotoUrl, let url = URL(string: urlString) {
            DispatchQueue.main.async {
                self.profileImageButton.sd_setImage(with: url, for: .normal, placeholderImage: placeholderProfileImage, options: [], completed: { (_, _, _, _) in
                    self.profileImageButton.isUserInteractionEnabled = true
                })
            }
        }
        
        DispatchQueue.main.async {
            if !UserController.shared.allChatsWithFriends.isEmpty{
            self.tableView.isHidden = false
            self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    @objc private func addFriendButtonTapped(_ sender: Any) {
        let addFriendVC = AddFriendViewController()
        
//        friendshipChangedListener = addListenerOnUser(listeningTo: DatabaseService.Collection.friends, completion: { (changes) in
//            if changes {
//                DispatchQueue.main.async {
//                    self.handleRefreshFriends()
//                }
//                //self.blockedUserListener?.remove()
//            }
//        })
        
        navigationController?.pushViewController(addFriendVC, animated: true)
    }
    
    @objc private func handleRefreshFriends() {
        print("🤶\(#function)")
        beginRefresh()
        self.fetchChatsWithFriends(completion: { (error) in
            self.endRefresh()
            if let error = error {
                print(error)
                
                return
            }
            
            self.reloadData()
            
        })
    }
    
    private func reloadData() {
        
            UserController.shared.allChatsWithFriends.sort(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                return chatWithFriend1.friend.username < chatWithFriend2.friend.username
            })
            
            DispatchQueue.main.async {
                self.tableView.isHidden = false
                self.tableView.reloadData()
            }
    }
    
    private func addListenerOnUser(listeningTo collection: String, completion: @escaping (Bool) -> Void = { _ in }) -> ListenerRegistration {
        return Firestore.firestore().collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid).collection(collection).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print(error)
                completion(false)
                return
            }
            if let changes = querySnapshot?.documentChanges, changes.count > 0,
                changes.contains(where: { $0.type == .added }) {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private func addListener(listeningTo collection: CollectionReference, completion: @escaping (Bool) -> Void = { _ in }) -> ListenerRegistration {
        return collection.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print(error)
                completion(false)
                return
            }
            if let changes = querySnapshot?.documentChanges, changes.count > 0 {
                completion(true)
            }
        }
    }
    private func addListener(listeningTo document: DocumentReference, completion: @escaping (Bool) -> Void = { _ in }) -> ListenerRegistration {
        return document.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print(error)
                completion(false)
                return
            }
            if let _ = snapshot {
                completion(true)
            }
        }
    }
    
    func newChatListener(chatUid: String, chat: Chat, index: Int) {
        Firestore.firestore().collection(DatabaseService.Collection.chats).document(chatUid).addSnapshotListener { (snapshot, error) in
            if let error = error {
                print(error)
                return
            }
            guard let doc = snapshot else { return }
            
            doc.metadata.hasPendingWrites
        }
    }
}

// MARK: - UI
private extension FriendsListViewController {
    func updateView() {
        view.backgroundColor = .white
        view.addSubviews([tableView])
        setupConstraints()
        setupNavigationBar()
    }
    
    func setupConstraints() {
        tableView.anchor(view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    func setupNavigationBar() {
        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: addFriendButton)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileImageButton)
    
        navigationItem.leftBarButtonItem?.customView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(settingsButtonTapped)))
        navigationController?.navigationBar.tintColor = .black
        
    }
    
    func deselectCell() {
        if let index = self.tableView.indexPathForSelectedRow{
            self.tableView.deselectRow(at: index, animated: true)
        }
    }
    
    func beginRefresh() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.hud.show(in: self.view)
            self.refreshControl.beginRefreshing()
        }
    }
    
    func endRefresh() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.hud.dismiss()
            self.refreshControl.endRefreshing()
        }
    }
}

// MARK: - Actions
private extension FriendsListViewController {
    @objc func settingsButtonTapped() {
        blockedUserListener = addListenerOnUser(listeningTo: DatabaseService.Collection.blocked)
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FriendsListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaders.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return UserController.shared.bestFriendsChats.count
        case 1:
            return UserController.shared.recentChatsWithFriends.count
        case 2:
            return UserController.shared.allChatsWithFriends.count
        case 3:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 3 {
            let goToAddFriendCell = tableView.dequeueReusableCell(withIdentifier: GoToAddFriendCell.reuseIdentifier, for: indexPath) as! GoToAddFriendCell
            goToAddFriendCell.delegate = self
            return goToAddFriendCell
        }
        
        let friendsListCell = tableView.dequeueReusableCell(withIdentifier: FriendsListCell.reuseIdentifier, for: indexPath) as! FriendsListCell
        
        var friend: User
        
        switch indexPath.section {
        case 0 where !UserController.shared.bestFriendsChats.isEmpty:
            friend = UserController.shared.bestFriendsChats[indexPath.row].friend
            let chatWithFriend = UserController.shared.bestFriendsChats[indexPath.row]
            friendsListCell.configure(with: chatWithFriend)
        
        case 1 where !UserController.shared.recentChatsWithFriends.isEmpty:
            friend = UserController.shared.recentChatsWithFriends[indexPath.row].friend
            let chatWithFriend = UserController.shared.recentChatsWithFriends[indexPath.row]
            friendsListCell.configure(with: chatWithFriend)
        
        case 2 where !UserController.shared.allChatsWithFriends.isEmpty:
            friend = UserController.shared.allChatsWithFriends[indexPath.row].friend
            let chatWithFriend = UserController.shared.allChatsWithFriends[indexPath.row]
            friendsListCell.configure(with: chatWithFriend)
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        
        
        friendsListCell.delegate = self
        friendsListCell.profileImageView.delegate = self
        
        return friendsListCell
    }
}

// MARK: - UITableViewDelegate
extension FriendsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let messagesViewController = MessagesViewController()
        
        var dataSource: [ChatWithFriend] = []
        
        switch indexPath.section {
        case 0:
            dataSource = UserController.shared.bestFriendsChats
        case 1:
            dataSource = UserController.shared.recentChatsWithFriends
        case 2:
            dataSource = UserController.shared.allChatsWithFriends
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        
        guard let friend = dataSource.get(at: indexPath.row)?.friend else {
            print("Oops! That index path no longer exists")
            return
        }
        
        guard let chatWithFriend = dataSource.get(at: indexPath.row) else {
            print("Oops! That index path no longer exists")
            return
        }
        
        if indexPath.section == 0 {
            friend.isBestFriend = true
        }
        
        let chat = dataSource[indexPath.row].chat
        
        messagesViewController.friend = friend
        messagesViewController.chat = chat
        messagesViewController.chatWithFriend = chatWithFriend
        
        navigationController?.pushViewController(messagesViewController, animated: true)
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 3 ? goToAddFriendCellHeight : 80
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0,
                                                        width: tableView.frame.width,
                                                        height: section == 3 ? goToAddFriendSectionHeight : sectionHeaderHeight))
        
        let label = UILabel()
        label.frame = headerView.frame
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = #colorLiteral(red: 0.7137254902, green: 0.7568627451, blue: 0.8, alpha: 1)
        
        switch section {
        case 0 where UserController.shared.bestFriendsChats.count > 0:
            label.text = sectionHeaders[section]
        case 1 where UserController.shared.recentChatsWithFriends.count > 0:
            label.text = sectionHeaders[section]
        case 2 where UserController.shared.allChatsWithFriends.count > 0:
            label.text = sectionHeaders[section]
        case 3 where UserController.shared.allChatsWithFriends.isEmpty:
            label.text = sectionHeaders[section]
            label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            label.textColor = WKTheme.darkGray
            label.numberOfLines = 0
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        headerView.addSubview(label)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0 where !UserController.shared.bestFriendsChats.isEmpty:
            return sectionHeaderHeight
        case 1 where !UserController.shared.recentChatsWithFriends.isEmpty:
            return sectionHeaderHeight
        case 2 where !UserController.shared.allChatsWithFriends.isEmpty:
            return sectionHeaderHeight
        case 3 where UserController.shared.allChatsWithFriends.isEmpty:
            return goToAddFriendSectionHeight
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

// MARK: - ProfileImageButtonDelegate
extension FriendsListViewController: ProfileImageButtonDelegate {
    func didTapProfileImageButton(_ sender: ProfileImageButton) {
        let cell = sender.superview?.superview as! FriendsListCell
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        var dataSource: [ChatWithFriend] = []
        var profileDetailsViewController: ProfileDetailsViewController
        var isBestFriend = false
        
        switch indexPath.section {
        case 0:
            dataSource = UserController.shared.bestFriendsChats
            isBestFriend = true
        case 1:
            dataSource = UserController.shared.recentChatsWithFriends
        case 2:
            dataSource = UserController.shared.allChatsWithFriends
            if UserController.shared.bestFriendUids.contains(
                dataSource[indexPath.row].friend.uid) {
                isBestFriend = true
            }
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        
        let friend = dataSource[indexPath.row].friend
        let chat = dataSource[indexPath.row].chat
        
        profileDetailsViewController = ProfileDetailsViewController(user: friend, isBestFriend: isBestFriend, addFriendState: .accepted)

        
        navigationController?.pushViewController(profileDetailsViewController, animated: true)
    }
}

// MARK: - FriendsListCellDelegate
extension FriendsListViewController: FriendsListCellDelegate {
    func didTapCameraButton(_ sender: PopButton) {
        let cell = sender.superview?.superview as! FriendsListCell
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        var dataSource: [ChatWithFriend] = []
        
        switch indexPath.section {
        case 0:
            dataSource = UserController.shared.bestFriendsChats
        case 1:
            dataSource = UserController.shared.recentChatsWithFriends
        case 2:
            dataSource = UserController.shared.allChatsWithFriends
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        
        let friend = dataSource[indexPath.row].friend
        let chat = dataSource[indexPath.row].chat
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraViewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        cameraViewController.friend = friend
        cameraViewController.chat = chat
        present(cameraViewController, animated: true, completion: nil)
    }
}

extension FriendsListViewController: GoToAddFriendCellDelegate {
    func handleGoToButton(_ sender: Any) {
        addFriendButtonTapped(sender)
    }
}

// MARK: - Fetch Chats With Friends
extension FriendsListViewController {
    func fetchChatsWithFriends(completion: @escaping (Error?) -> Void) {
        UserController.shared.allChatsWithFriends = []
        UserController.shared.currentUser?.friendsUids = []
        
        let dbs = DatabaseService()
        dbs.fetchUserChats(for: UserController.shared.currentUser!, completion: { (userChats, error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            guard let userChats = userChats, userChats.count > 0 else { completion(error); return }
            
            var i = 0
            for chatUid in userChats {
//                let chatUid = userChats[i]
                
                dbs.fetchChat(chatUid, completion: { (chat, error) in
                    if let error = error {
                        print(error)
                        completion(error)
                        return
                    }

                    guard let chat = chat else { print("chat does not exists"); return }
                    
                    dbs.fetchLatestMessage(in: chat, completion: { (message, error) in
                        guard let message = message else { return }
                        
                        chat.latestMessage = message
                        
                    })
                    
                    dbs.fetchFriend(in: chat, completion: { (user, error) in
                        if let error = error {
                            print(error)
                            completion(error)
                            return
                        }
                        guard let user = user else { return }
                       
                        if !UserController.shared.blockedUids.contains(user.uid) {
                            
                            let friend = UserController.shared.bestFriendUids.contains(user.uid) ? Friend(user: user, isBestFriend: true) : Friend(user: user)
                            
                            UserController.shared.currentUser?.friendsUids.insert(user.uid)
                            
                            UserController.shared.allChatsWithFriends.append((friend: friend, chat: chat))
                            i += 1
                        }
                        
                        // So fetchChatsWithFriends only completes once when all users are fetched
                        //if i >= userChats.count {
                            print("Fetched Chat With Friends and is now completing")
                            completion(nil)
                        //}
                    })
                })
                
            }
        })
    }
}


