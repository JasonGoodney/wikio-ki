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
    
    
    
    var indexPathToReload: IndexPath?
    private let cellId = FriendsListCell.reuseIdentifier
    
    private let sectionHeaders = ["RECENTS", "MY FRIENDS"]
    private var chatsWithFriends: [ChatWithFriend] = []
    private var recentChatsWithFriends: [ChatWithFriend] = []
    
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
    
    private lazy var launchCameraButton: SwiftyCamButton = {
        let button = SwiftyCamButton(type: .system)
        button.delegate = self
        return button
    }()
    
    private lazy var newConversationButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newConversationButtonTapped))

    private let profileImageButton: ProfileImageButton = {
        let button = ProfileImageButton(height: 32, width: 32)
        return button
    }()
    
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
                
                Firestore.firestore()
                    .collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid)
                    .collection(DatabaseService.Collection.friendRequests).addSnapshotListener { (snapshot, error) in
                        
                        if let error = error {
                            print(error)
                            return
                        }
                        
                        guard let docChanges = snapshot?.documentChanges else { return }
                        
                        if docChanges.count > 0 {
                            self.newConversationButton.tintColor = .blue
                        } else {
                            self.newConversationButton.tintColor = .black
                        }
                }
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
        
//        if UserController.shared.currentUser == nil {
//            UserController.shared.fetchCurrentUser { (success) in
//                if success {
//                    self.endRefresh()
//
//
//                }
//            }
//        } else {
//            if let urlString = UserController.shared.currentUser?.profilePhotoUrl, let url = URL(string: urlString) {
//                DispatchQueue.main.async {
//                    self.profileImageButton.sd_setImage(with: url, for: .normal)
//                }
//            }
//        }
        if let tintColor = newConversationButton.tintColor, tintColor == .black && UserController.shared.currentUser != nil {
            Firestore.firestore()
                .collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid)
                .collection(DatabaseService.Collection.friendRequests).addSnapshotListener { (snapshot, error) in
                    
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    guard let docChanges = snapshot?.documentChanges else { return }
                    
                    if docChanges.count > 0 {
                        self.newConversationButton.tintColor = .blue
                    } else {
                        self.newConversationButton.tintColor = .black
                    }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    @objc private func newConversationButtonTapped(_ sender: UIBarButtonItem) {
        let addFriendVC = AddFriendViewController()
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
  
            if self.chatsWithFriends.count == 0 {
                self.noFriendsLabel.isHidden = false
                self.tableView.isHidden = true
                
            } else {
                self.noFriendsLabel.isHidden = true
                self.tableView.isHidden = false
                
                self.chatsWithFriends.sort(by: { (chatWithFriend1, chatWithFriend2) -> Bool in
                    return chatWithFriend1.chat.lastChatUpdateTimestamp > chatWithFriend2.chat.lastChatUpdateTimestamp
                })

                print("Fetched Chat With Friends")
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
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
        navigationItem.rightBarButtonItem = newConversationButton
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
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension FriendsListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatsWithFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! FriendsListCell
        
        var friend: User
        
        friend = chatsWithFriends[indexPath.row].friend
        
        
        cell.configure(with: friend)
        cell.delegate = self
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension FriendsListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friend = chatsWithFriends[indexPath.row].friend
        let chat = chatsWithFriends[indexPath.row].chat
        
        let messagesViewController = MessagesViewController()
        messagesViewController.friend = friend
        messagesViewController.chat = chat
        navigationController?.pushViewController(messagesViewController, animated: true)
    
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        
        let label = UILabel()
        label.frame = headerView.frame
        label.textAlignment = .center
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = #colorLiteral(red: 0.7137254902, green: 0.7568627451, blue: 0.8, alpha: 1)

        if chatsWithFriends.count > 0 {
            label.text = sectionHeaders[1]
            headerView.addSubview(label)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

}

// MARK: - SwiftyCamButtonDelegate
extension FriendsListViewController: SwiftyCamButtonDelegate {
    func buttonDidBeginLongPress() {}
    func buttonDidEndLongPress() {}
    func longPressDidReachMaximumDuration() {}
    
    func setMaxiumVideoDuration() -> Double {
        return 0.0
    }
    
    func buttonWasTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraViewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        present(cameraViewController, animated: false, completion: nil)
    }
}

extension FriendsListViewController: FriendsListCellDelegate {
    func didTapCameraButton(_ sender: UIButton) {
        let cell = sender.superview?.superview as! FriendsListCell
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let friend = chatsWithFriends[index].friend
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraViewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        cameraViewController.friend = friend
        present(cameraViewController, animated: false, completion: nil)
    }
}

extension FriendsListViewController: OpenCameraToolbarDelegate {
    func didTapOpenCameraButton() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let cameraViewController = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as! CameraViewController
        present(cameraViewController, animated: false, completion: nil)
    }
}

// MARK: - Fetch Chats With Friends
extension FriendsListViewController {
    func fetchChatsWithFriends(completion: @escaping (Error?) -> Void) {
        let dbs = DatabaseService()
        dbs.fetchUserChats(for: UserController.shared.currentUser!, completion: { (userChats, error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            guard let userChats = userChats, userChats.count > 0 else { completion(error); return }
            
            for chatUid in userChats {
                dbs.fetchChat(chatUid, completion: { (chat, error) in
                    if let error = error {
                        print(error)
                        completion(error)
                        return
                    }
                    
                    self.chatsWithFriends = []
                    
                    guard let chat = chat else { return }
                    dbs.fetchFriend(in: chat, completion: { (user, error) in
                        if let error = error {
                            print(error)
                            completion(error)
                            return
                        }
                        guard let friend = user else { return }
                        if !UserController.shared.blockedUids.contains(friend.uid) {
                            self.chatsWithFriends.append((friend: friend as! Friend, chat: chat))
                            UserController.shared.currentUser?.friendsUids.insert(friend.uid)
                            UserController.shared.allChatsWithFriends.append((friend: friend as! Friend, chat: chat))
                        }
                        completion(nil)
                    })
                })
            }
        })
    }
}
