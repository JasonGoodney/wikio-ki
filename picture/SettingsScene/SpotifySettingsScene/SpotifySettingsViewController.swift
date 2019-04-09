//
//  SpotifySettingsViewController.swift
//  picture
//
//  Created by Jason Goodney on 4/7/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit

class SpotifySettingsViewController: UIViewController {
    
    private let cellTitles = ["Connect", "Public", "Playable"]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SpotifyCell")
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.titleView = NavigationTitleLabel(title: "Spotify")
        
        setupLayout()
    }
    
    private func setupLayout() {
        view.backgroundColor = .white
        
        view.addSubviews([tableView])
        
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    @objc func switchChanged(_ sender : UISwitch!){
        
        print("table row switch Changed \(sender.tag)")
        print("The switch is \(sender.isOn ? "ON" : "OFF")")
        
        if sender.tag == 0 {
            
        }
    }

    
}

extension SpotifySettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "SpotifyCell")
        
        cell.textLabel?.text = cellTitles[indexPath.row]
        
        let switchView = UISwitch(frame: .zero)
        switchView.setOn(false, animated: true)
        switchView.tag = indexPath.row // for detect which row switch Changed
        switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchView
        
        return cell
    }
}
