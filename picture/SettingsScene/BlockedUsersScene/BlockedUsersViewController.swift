//
//  BlockedUsersViewController.swift
//  picture
//
//  Created by Jason Goodney on 1/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class BlockedUsersViewController: UIViewController {

    private var blockedUsers: [User] = []
    
    private let noOneBlockedLabel: UILabel = {
        let label = UILabel()
        label.text = "No one blocked"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = WKTheme.darkGray
        return label
    }()
    
    private let cellId = BlockedUserCell.reuseIdentifier
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.register(BlockedUserCell.self, forCellReuseIdentifier: cellId)
        view.separatorStyle = .none
        view.backgroundColor = .white
        return view
    }()
    
    private let titleLabel = NavigationTitleLabel(title: "Blocked")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        
        if UserController.shared.blockedUids.count == 0 {
            noOneBlockedLabel.isHidden = false
            tableView.isHidden = true
        } else {
            noOneBlockedLabel.isHidden = true
            tableView.isHidden = false
            
            let dbs = DatabaseService()
            for uid in UserController.shared.blockedUids {
                dbs.fetchUser(for: uid) { (user, error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    guard let user = user else { return }
                    self.blockedUsers.append(user)
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }

    private func setupLayout() {
        view.backgroundColor = .white
        view.addSubviews(noOneBlockedLabel, tableView)
        
        noOneBlockedLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 0, bottom: 0, right: 0))
        
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
        
        navigationItem.titleView = titleLabel
    }

}

extension BlockedUsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! BlockedUserCell
        
        cell.delegate = self
        
        let blockedUser = blockedUsers[indexPath.row]
        cell.configure(withBlockedUser: blockedUser)
        cell.unblockButton.tag = indexPath.row
        
        return cell
    }
}

extension BlockedUsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

extension BlockedUsersViewController: BlockedUserCellDelegate {
    func handleUnblockUser(sender: UIButton) {

        unblockActionSheet { (success) in
            if success {
                let user = self.blockedUsers[sender.tag]
                let dbs = DatabaseService()
                dbs.unblock(user: user, completion: { (error) in
                    if let error = error {
                        print(error)
                        return
                    }
                    UserController.shared.blockedUids.removeAll(where: { (uid) -> Bool in
                        return uid == user.uid
                    })
                    self.blockedUsers.removeAll(where: { (blockedUser) -> Bool in
                        return blockedUser == user
                    })
                    print("\(user.username) unblocked")
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                })
                
            }
        }
    }
}
