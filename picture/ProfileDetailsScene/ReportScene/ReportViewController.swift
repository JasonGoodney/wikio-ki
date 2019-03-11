//
//  ReportViewController.swift
//  picture
//
//  Created by Jason Goodney on 3/11/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import MessageUI
import JGProgressHUD

class ReportViewController: UIViewController {
    
    private var user: User? = nil
    private var friend: Friend? = nil
    
    private var userToReport: User {
        if let user = user {
            return user
        } else {
            if friend!.isBestFriend {
                isBestFriend = true
            }
            return friend!
        }
    }
    
    private var isBestFriend = false
    
    private let titleLabel = NavigationTitleLabel(title: "Report an issue")
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    private let userReports: [(title: String, type: UserReportReason)] = [
        (title: "It's suspicious or spam", type: .spamContent),
        (title: "Their posts include hateful or abusive content", type: .hatefulContent),
        (title: "Their posts include sensitive content", type: .sensitiveContent),
        (title: "It appears their accout is hacked", type: .hackedAccount),
        (title: "They're pretending to be me or someone else", type: .impersonationAcount),
    ]
    
    init(friend: Friend) {
        self.friend = friend
        super.init(nibName: nil, bundle: nil)
    }
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCurrentBackButton(title: "Cancel")
    }
    
    private func setupLayout() {
        view.backgroundColor = .white

        view.addSubviews([tableView])
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func sendEmailReport(subject: String, body: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.setToRecipients(["teamwikioki@gmail.com"])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else {
            print("Can not send mail")
        }
    }
    
    private func emailBody(withReason reason: String) -> String {
        return "\(UserController.shared.currentUser!.username)(\(UserController.shared.currentUser!.uid)) is reporting \(userToReport.username)(\(userToReport.uid)) for \(reason)"
    }
    
    private func changeBestFriendStatus(isBestFriend: Bool, completion: @escaping ErrorCompletion) {
        let dbs = DatabaseService()
        let document = DatabaseService.userReference(forPathUid: UserController.shared.currentUser!.uid).collection(DatabaseService.Collection.friends).document(userToReport.uid)
        
        dbs.updateDocument(document, withFields: ["isBestFriend": isBestFriend], completion: completion)
        
    }
    
    private func report(reason: UserReportReason) {
        let dbs = DatabaseService()
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Reporting"
        hud.show(in: self.view)
        dbs.report(user: userToReport, forReason: reason) { (error) in
            if let error = error {
                print(error)
                return
            }
            dbs.block(user: self.userToReport, completion: { (error) in
                if let error = error {
                    print(error)
                    return
                }
                if self.isBestFriend {
                    self.changeBestFriendStatus(isBestFriend: false, completion: { (error) in
                        DispatchQueue.main.async {
                            UserController.shared.bestFriendUids.removeAll(where: { $0 == self.userToReport.uid })
                        }
                    })
                }
                if !UserController.shared.blockedUids.contains(self.userToReport.uid) {
                    UserController.shared.blockedUids.append(self.userToReport.uid)
                }
                DispatchQueue.main.async {
                    hud.dismiss()
                    self.navigationController?.popToRootViewController(animated: true)
                }
            })
        }
    }
}

extension ReportViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        
        let report = userReports[indexPath.row]
        
        cell.textLabel?.text = report.title
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
}

extension ReportViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userReport = userReports[indexPath.row]
        report(reason: userReport.type)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = "Help us understand the problem. What issue with \(userToReport.username) are you reporting?"
        return title
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let title = "Reporting a user will also block them."
        return title
    }
}
