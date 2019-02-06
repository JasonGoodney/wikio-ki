//
//  AddMoreFriendsViewController.swift
//  picture
//
//  Created by Jason Goodney on 2/3/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class AddMoreFriendsViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.delegate = self
        view.dataSource = self
//        view.register(UITableViewCell.self, forCellReuseIdentifier: "")
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }
    
}

// MARK: - UI
private extension AddMoreFriendsViewController {
    func setupLayout() {
        view.addSubview(tableView)
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AddMoreFriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return UserController.shared.allChatsWithFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "")
        
        cell.accessoryType = .checkmark
        
        let friend = UserController.shared.allChatsWithFriends[indexPath.row].friend
        
        cell.textLabel?.text = friend.username
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AddMoreFriendsViewController: UITableViewDelegate {
    
}
