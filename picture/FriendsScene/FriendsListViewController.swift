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

class FriendsListViewController: UIViewController {
    
    // Firebase Listeners
    var friendRequestListener: ListenerRegistration?
    var friendshipChangedListener: ListenerRegistration?
    var blockedUserListener: ListenerRegistration?
    var chatUpdateListener: ListenerRegistration?
    
    var indexPathToReload: IndexPath?
    private let cellId = FriendsListCell.reuseIdentifier
    
    private let sectionHeaders = ["BEST FRIENDS", "RECENTS", "MY FRIENDS"]
    private let sectionHeaderHeight: CGFloat = 50

    
    // MARK: - Subviews
    private var hud = JGProgressHUD(style: .dark)
    private let noFriendsLabel: UILabel = {
        let label = UILabel()
        label.text = "No friends :/\n\nAdd some :)"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = WKTheme.darkGray
        label.isHidden = true
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(FriendsListCell.self, forCellReuseIdentifier: cellId)
        view.separatorStyle = .none
        view.backgroundColor = .white
        return view
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(handleRefreshFriends), for: UIControl.Event.valueChanged)
        return view
    }()
    
    private let titleLabel = NavigationTitleLabel(title: "Wikio Ki")
    
    private lazy var addFriendButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        button.setImage(#imageLiteral(resourceName: "icons8-plus_math-1").withRenderingMode(.alwaysTemplate), for: .normal)
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
        self.friendRequestListener?.remove()
        friendshipChangedListener?.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
        
        UserController.shared.fetchCurrentUser { (success) in
            if success {
                if let urlString = UserController.shared.currentUser?.profilePhotoUrl, let url = URL(string: urlString) {
                    DispatchQueue.main.async {
                        self.profileImageButton.sd_setImage(with: url, for: .normal, completed: { (_, _, _, _) in
                            self.profileImageButton.isUserInteractionEnabled = true
                        })
                    }
                }
                
                self.handleRefreshFriends()
                
                self.friendRequestListener = Firestore.firestore()
                    .collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid)
                    .collection(DatabaseService.Collection.friendRequests).addSnapshotListener { (snapshot, error) in
                        
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        guard let docChanges = snapshot?.documentChanges else { return }
                        
                        docChanges.forEach({ (diff) in
                            if diff.type == .added {
                                #warning("pop button animation")
                                return
                            }
                        })
                }
                
                let value = UserController.shared.currentUser?.uid as Any
                
//                Firestore.firestore().collection(DatabaseService.Collection.chats)
//                    .whereField(Chat.Keys.memberUids, arrayContains: value).getDocuments(completion: { (snapshot, error) in
//                        if let docs = snapshot?.documents {
//                            docs.forEach({
//                                print($0.data())
//                                print("\n")
//                            })
//                        }
//                    })
                
                self.chatUpdateListener = Firestore.firestore().collection(DatabaseService.Collection.chats)
                    .whereField(Chat.Keys.memberUids, arrayContains: value)
                    .addSnapshotListener({ (querySnapshot, error) in
                    
                        guard let snapshot = querySnapshot else {
                            print("Error fetching documents: \(error!)")
                            return
                        }
                        
                        if snapshot.documentChanges.contains(where: { $0.type == .modified }) {
                            UIApplication.shared.isNetworkActivityIndicatorVisible = true
                            self.fetchChatsWithFriends(completion: { (error) in
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                if let error = error {
                                    print(error)
                                    
                                    return
                                }
                                
                                self.reloadData()
                                
                            })
                        }
                        
                        if snapshot.documentChanges.count > 0 {
                            
                            
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
                self.profileImageButton.sd_setImage(with: url, for: .normal, completed: { (_, _, _, _) in
                    self.profileImageButton.isUserInteractionEnabled = true
                })
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        friendRequestListener?.remove()
        friendshipChangedListener?.remove()
        blockedUserListener?.remove()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    @objc private func addFriendButtonTapped(_ sender: UIBarButtonItem) {
        let addFriendVC = AddFriendViewController()
        if friendRequestListener != nil {
            friendRequestListener?.remove()
            self.addFriendButton.setImage(#imageLiteral(resourceName: "icons8-plus_math-1"), for: .normal)
        }
        
        friendshipChangedListener = addListenerOnUser(listeningTo: DatabaseService.Collection.friends)
        
        navigationController?.pushViewController(addFriendVC, animated: true)
    }
    
    @objc private func handleRefreshFriends() {
        
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
        if UserController.shared.allChatsWithFriends.count == 0 {
            self.noFriendsLabel.isHidden = false
            self.tableView.isHidden = true
            self.view.addGestureRecognizer(self.doubleTapRefresh)
            
        } else {
            self.noFriendsLabel.isHidden = true
            self.tableView.isHidden = false
            self.view.removeGestureRecognizer(self.doubleTapRefresh)
            
            UserController.shared.allChatsWithFriends.sort(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                return chatWithFriend1.friend.username < chatWithFriend2.friend.username
            })
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func addListenerOnUser(listeningTo collection: String, completion: @escaping (Bool) -> Void = { _ in }) -> ListenerRegistration {
        return Firestore.firestore().collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid).collection(collection).addSnapshotListener { (querySnapshot, error) in
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
}

// MARK: - UI
private extension FriendsListViewController {
    func updateView() {
        view.backgroundColor = .white
        view.addSubviews(tableView, noFriendsLabel)
        setupConstraints()
        setupNavigationBar()
    }
    
    func setupConstraints() {
        tableView.anchor(view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        noFriendsLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 0, bottom: 0, right: 0))

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
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! FriendsListCell
        
        var friend: User
        
        switch indexPath.section {
        case 0 where !UserController.shared.bestFriendsChats.isEmpty:
            friend = UserController.shared.bestFriendsChats[indexPath.row].friend
            cell.configure(with: friend)
        case 1 where !UserController.shared.recentChatsWithFriends.isEmpty:
            friend = UserController.shared.recentChatsWithFriends[indexPath.row].friend
            cell.configure(with: friend)
        case 2 where !UserController.shared.allChatsWithFriends.isEmpty:
            friend = UserController.shared.allChatsWithFriends[indexPath.row].friend
            cell.configure(with: friend)
        default:
            print("SECTION ERROR 🤶\(#function)")
        }
        
        
        cell.delegate = self
        cell.profileImageView.delegate = self
        
        return cell
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
        
        let friend = dataSource[indexPath.row].friend
        
        if indexPath.section == 0 {
            friend.isBestFriend = true
        }
        
        let chat = dataSource[indexPath.row].chat
        
        messagesViewController.friend = friend
        messagesViewController.chat = chat
        
        navigationController?.pushViewController(messagesViewController, animated: true)
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: sectionHeaderHeight))
        
        let label = UILabel()
        label.frame = headerView.frame
        label.textAlignment = .center
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = #colorLiteral(red: 0.7137254902, green: 0.7568627451, blue: 0.8, alpha: 1)
        
        switch section {
        case 0 where UserController.shared.bestFriendsChats.count > 0:
            label.text = sectionHeaders[section]
            headerView.addSubview(label)
        case 1 where UserController.shared.recentChatsWithFriends.count > 0:
            label.text = sectionHeaders[section]
            headerView.addSubview(label)
        case 2 where UserController.shared.allChatsWithFriends.count > 0:
            label.text = sectionHeaders[section]
            headerView.addSubview(label)
        default:
            print("SECTION ERROR 🤶\(#function)")
        }

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
        default:
            return 0
        }
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
        
        friendshipChangedListener = addListenerOnUser(listeningTo: DatabaseService.Collection.friends, completion: { (changes) in
            if changes {
                DispatchQueue.main.async {
                    self.handleRefreshFriends()
                }
                //self.blockedUserListener?.remove()
            }
        })
//
//        blockedUserListener = addListenerOnUser(listeningTo: DatabaseService.Collection.blocked, completion: { (changes) in
//            if changes {
//                DispatchQueue.main.async {
//                    self.handleRefreshFriends()
//                }
//                //self.friendshipChangedListener?.remove()
//            }
//        })
        
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

//extension FriendsListViewController: OpenCameraToolbarDelegate {
//    func didTapOpenCameraButton() {
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let cameraViewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
//
//        present(cameraViewController, animated: false, completion: nil)
//    }
//}

// MARK: - Fetch Chats With Friends
extension FriendsListViewController {
    func fetchChatsWithFriends(completion: @escaping (Error?) -> Void) {
        UserController.shared.allChatsWithFriends = []
        
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
//                        if i == userChats.count - 1 {
                            print("Fetched Chat With Friends and is now completing")
                            completion(nil)
//                        }
                    })
                })
                
            }
        })
    }
}


