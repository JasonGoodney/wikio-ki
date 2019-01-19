//
//  AddFriendViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/24/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import FirebaseFirestore
import JGProgressHUD

class AddFriendViewController: UITableViewController {
    
    private var sentRequestUids: [String] = []
    private var friendRequests: [User] = []
    private var searchedUser: User?
    private let searchController: UISearchController = {
        let bar = UISearchController(searchResultsController: nil)
        bar.searchBar.placeholder = "Search"
        bar.searchBar.autocapitalizationType = .none
        bar.hidesNavigationBarDuringPresentation = false
        bar.dimsBackgroundDuringPresentation = false
        bar.obscuresBackgroundDuringPresentation = false
        bar.definesPresentationContext = true
        bar.searchBar.showsCancelButton = false
        return bar
    }()
    
    private let titleLabel = NavigationTitleLabel(title: "Add Friends")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        tableView.register(AddFriendCell.self, forCellReuseIdentifier: AddFriendCell.reuseIdentifier)
        
        searchController.delegate = self
        searchController.searchBar.delegate = self
        navigationItem.titleView = titleLabel
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchController.isActive = true
        DispatchQueue.main.async{
            self.searchController.searchBar.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.backgroundColor = .white
        
        fetchFriendRequests { (error) in
            if let error = error {
                print(error)
                return
            }
            self.reloadData()
        }
        
        fetchSentRequests()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        if self.presentedViewController != nil {
            self.presentedViewController?.dismiss(animated: false, completion: nil)
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return searchedUser == nil ? 0 : 1
        } else if section == 1 {
            return friendRequests.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AddFriendCell.reuseIdentifier, for: indexPath) as! AddFriendCell
        
        cell.delegate = self
        cell.profileImageView.delegate = self
        
        if indexPath.section == 0 {
            
            if let user = searchedUser {
                if sentRequestUids.contains(user.uid) {
                    cell.updateView(forAddFriendState: .added)
                } else if friendRequests.contains(user) {
                    cell.updateView(forAddFriendState: .requested)
                } else if UserController.shared.blockedUids.contains(user.uid) {
                    cell.updateView(forAddFriendState: .blocked)
                } else {
                    cell.updateView(forAddFriendState: .add)
                }
                cell.configure(with: user)
            }
        } else if indexPath.section == 1 {
            
            let friendRequest = friendRequests[indexPath.row]
            
            cell.configure(with: friendRequest)
            cell.updateView(forAddFriendState: .requested)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
        
        let label = UILabel()
        label.frame = headerView.frame
        label.textAlignment = .center
        
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = #colorLiteral(red: 0.7137254902, green: 0.7568627451, blue: 0.8, alpha: 1)
        
        switch section {
        case 1 where friendRequests.count > 0:
            label.text = "ADDED ME"
            headerView.addSubview(label)
        default:
            ()
        }

        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        }
        return 50
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("will delete row \(indexPath.row)")
        }
    }

    private func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    private func sendFriendRequest(to user: User, completion: @escaping (AddFriendState?, Error?) -> Void) {
        guard let currentUser = UserController.shared.currentUser else { return }
        let addFriendState: AddFriendState = .requested
        let friendRequestData: [String: Any] = ["requestedBy": currentUser.uid]
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Sending"
        hud.show(in: view)
        
        Firestore.firestore().collection(DatabaseService.Collection.users)
            .document(user.uid).collection(DatabaseService.Collection.friendRequests)
            .document(currentUser.uid).setData(friendRequestData) { (error) in
                hud.dismiss()
                if let error = error {
                    print(error)
                    completion(nil, error)
                    return
                }
                
                print("\(user.username) has a friend request from \(currentUser.username)")
                completion(addFriendState, nil)
        }
        
        let sentRequestData: [String: Any] = ["sentTo": user.uid]
        Firestore.firestore().collection(DatabaseService.Collection.users)
            .document(currentUser.uid).collection(DatabaseService.Collection.sentRequests)
            .document(user.uid).setData(sentRequestData, merge: true) { (error) in
                if let error = error {
                    print(error)
                    completion(nil, error)
                    return
                }
                
                print("\(currentUser.username) sent request to \(user.username)")
                self.sentRequestUids.append(user.uid)
                completion(addFriendState, nil)
        }
    }
    
    private func acceptFriendRequest(from user: User, completion: @escaping ErrorCompletion) {
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Accepting"
        hud.show(in: view)
        guard let currentUser = UserController.shared.currentUser else { return }

        currentUser.addFriend(user)
        user.addFriend(currentUser)
        
        removeFriendRequest(to: UserController.shared.currentUser!, from: user) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            completion(nil)
        }
        
        removeSentRequest(from: user, to: UserController.shared.currentUser!) { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            completion(nil)
        }
        
        let chat = Chat(memberUids: [currentUser.uid, user.uid], lastMessageSent: "", lastSenderUid: "")
        chat.unread = [currentUser.uid: 0, user.uid: 0]
        let dbs = DatabaseService()
        dbs.createInitialChat(chat) { (error) in
            hud.dismiss()
            if let error = error {
                print(error)
                return
            }
        }
    }
    
    private func removeFriendRequest(to: User, from: User, completion: @escaping ErrorCompletion) {
        Firestore.firestore().collection(DatabaseService.Collection.users).document(to.uid).collection(DatabaseService.Collection.friendRequests).document(from.uid).delete { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            print("Removed request to \(to.uid)")
            completion(nil)
        }
    }
    
    private func removeSentRequest(from: User, to: User, completion: @escaping ErrorCompletion) {
        Firestore.firestore()
            .collection(DatabaseService.Collection.users).document(from.uid)
            .collection(DatabaseService.Collection.sentRequests).document(to.uid).delete { (error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            print("removed sent request from \(from.uid)")
            completion(nil)
        }
    }
    
    private func fetchSentRequests() {
        guard let currentuser = UserController.shared.currentUser else { return }
        Firestore.firestore()
            .collection(DatabaseService.Collection.users).document(currentuser.uid)
            .collection(DatabaseService.Collection.sentRequests).getDocuments { (snapshot, error) in
            if let error = error {
                print(error)
                
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            self.sentRequestUids = []
            docs.forEach({ (doc) in
                let dict = doc.data()
                self.sentRequestUids.append(dict.values.first! as! String)
                
            })
            
        }
    }
   
    private func fetchFriendRequests(completion: @escaping ErrorCompletion) {
        guard let currentUser = UserController.shared.currentUser else { return }
        Firestore.firestore()
            .collection(DatabaseService.Collection.users).document(currentUser.uid)
            .collection(DatabaseService.Collection.friendRequests).getDocuments { (snapshot, error) in
            if let error = error {
                print(error)
                completion(error)
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            self.friendRequests = []
            docs.forEach({ (doc) in
                let uid = doc.data().values.first as! String
                Firestore.firestore()
                    .collection(DatabaseService.Collection.users).document(uid).getDocument(completion: { (snapshot, error) in
                    if let error = error {
                        print(error)
                        completion(error)
                        return
                    }
                    guard let dict = snapshot?.data() else { return }
                    let user = User(dictionary: dict)
                    self.friendRequests.append(user)
                    self.reloadData()
                })
            })
        }
    }
  
}

extension AddFriendViewController: AddFriendDelegate {
    func didTapCancelReceivedRequest(cell: AddFriendCell, user: User, state: AddFriendState) {
        searchController.isActive = false
        if state == .requested {
            destructiveAlert(alertTitle: "Decline friend request from \(user.username)", actionTitle: "Yes") { (removed) in
                if removed {
                    self.removeFriendRequest(to: UserController.shared.currentUser!, from: user) { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                        self.friendRequests.removeAll(where: { (from) -> Bool in
                            return from == user
                        })
                        DispatchQueue.main.async {
                            guard let indexPath = self.tableView.indexPath(for: cell) else { return }
                            //                        self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            self.tableView.reloadData()
                        }
                    }
                    
                    self.removeSentRequest(from: user, to: UserController.shared.currentUser!) { (error) in
                        if let error = error {
                            print(error)
                            return
                        }
                    }
                    
                    
                }
            }
            
        }
    }
    
    func didTapAddFriendButton(cell: AddFriendCell, user: User, state: AddFriendState) {
        let dbs = DatabaseService()
        switch state {
        case .add:
            sendFriendRequest(to: user) { (state, error) in
                if let error = error {
                    print(error)
                    return
                }
                cell.updateView(forAddFriendState: .added)
            }
        case .added:
            searchController.dismiss(animated: true)
            print("Removing friend request sent to \(user.username)")
            self.removeFriendRequest(to: user, from: UserController.shared.currentUser!) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("Removed friend request to \(user.username)")
            }
            
            self.removeSentRequest(from: UserController.shared.currentUser!, to: user) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                print("Removed friend request by me")
            }
            
            DispatchQueue.main.async {
                cell.updateView(forAddFriendState: .add)
            }
        case .requested:
            acceptFriendRequest(from: user) { (error) in
                if let error = error {
                    print(error)
                    return
                }
                
                cell.updateView(forAddFriendState: .accepted)

                print(UserController.shared.currentUser!.username, "and", user.username, "are friends")
            }
        case .accepted:
            print("Message start new message with user \(user.uid)")
        case .blocked:
            print("Alert to unblock user")
        } 
    }
}

extension AddFriendViewController: ProfileImageButtonDelegate {
    func didTapProfileImageButton(_ sender: ProfileImageButton) {
        searchController.isActive = false
        let cell = sender.superview as! AddFriendCell
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        var user: Friend?
        
        switch indexPath.section {
        case 0 where searchedUser != nil:
            user = Friend(user: searchedUser!)
        case 1:
            user = Friend(user: self.friendRequests[indexPath.row])
        default:
            print("Section Error 🤶\(#function)")
        }
        
        guard let userToPass = user else { return }
        let profileDetailsViewController = ProfileDetailsViewController(user: userToPass, addFriendState: cell.addFriendState)
        navigationController?.pushViewController(profileDetailsViewController, animated: true)
        
    }
}

extension AddFriendViewController: UISearchControllerDelegate {
    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
}

extension AddFriendViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchedUser = nil
        reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            searchedUser = nil
            reloadData()
        } else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            let dbs = DatabaseService()
            dbs.fetchSearchedUser(with: searchText.lowercased()) { (searchedUser, error) in
                if let error = error {
                    print(error)
                    return
                }
//                || self.friendRequests.contains(searchedUser)
//                || UserController.shared.blockedUids.contains(searchedUser.uid)
                guard let searchedUser = searchedUser else { return }
                if UserController.shared.currentUser == searchedUser
                    
                    || (UserController.shared.currentUser?.friendsUids.contains((searchedUser.uid)))!
                    || UserController.shared.blockedUids.contains(searchedUser.uid)
                    
                {
                    self.searchedUser = nil
                } else {
                    self.searchedUser = searchedUser
                    self.reloadData()
                }
            }
        }
    }
}
