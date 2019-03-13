//
//  ReportedViewController.swift
//  picture
//
//  Created by Jason Goodney on 3/12/19.
//  Copyright © 2019 Jason Goodney. All rights reserved.
//

import UIKit
import MessageUI

class ReportedViewController: UIViewController {

    private var reportedUser: User!
    
    private let titleLabel = NavigationTitleLabel(title: "Report an issue")
    
    private let thanksLabel = UILabel()
    private let contactUsLabel = UILabel()
    private lazy var blockDetailsLabel: UILabel = {
        let label = UILabel()
        label.attributedText = blockDetailsAttributedText()
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var blockButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.red, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.red.cgColor
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(blockButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var contactUsButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(Theme.buttonBlue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = Theme.buttonBlue.cgColor
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(contactUsButtonTapped), for: .touchUpInside)
        button.setTitle("Contact Us", for: .normal)
        return button
    }()
    
    init(user: User) {
        self.reportedUser = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubviews([thanksLabel, blockButton, blockDetailsLabel, contactUsLabel, contactUsButton])
        view.backgroundColor = .white

        navigationItem.titleView = titleLabel
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        
        thanksLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 16))
        
        thanksLabel.attributedText = thanksLabelAttributedText()
        thanksLabel.numberOfLines = 0
        
        blockButton.anchor(top: thanksLabel.bottomAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 24, left: 16, bottom: 0, right: 16), size: .init(width: 0, height: 44))
        blockButton.setTitle("Block \(reportedUser.username)", for: .normal)
        
        blockDetailsLabel.anchor(top: blockButton.bottomAnchor, leading: blockButton.leadingAnchor, bottom: nil, trailing: blockButton.trailingAnchor, padding: .init(top: 16, left: 0, bottom: 0, right: 0))
        
        contactUsButton.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 16, bottom: 24, right: 16), size: .init(width: 0, height: 44))
        
        contactUsLabel.anchor(top: nil, leading: view.leadingAnchor, bottom: contactUsButton.topAnchor, trailing: view.trailingAnchor, padding: .init(top: 0, left: 16, bottom: 16, right: 16))
        contactUsLabel.attributedText = contactUsLabelAttributedText()
        contactUsLabel.numberOfLines = 0
        
        
    }
    
    @objc private func doneButtonTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func blockButtonTapped() {
        print("🤶\(#function)")
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let dbs = DatabaseService()
        dbs.block(user: reportedUser) { (error) in
            if let error = error {
                print(error)
                return
            }
            print("BLOCKED")
            UserController.shared.blockedUids.append(self.reportedUser.uid)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.navigationController?.popToRootViewController(animated: true)
            }
            
        }
    }
    
    @objc private func contactUsButtonTapped() {
        sendEmailReport(subject: "[REPORT] ", body: "")
    }
    
    private func thanksLabelAttributedText() -> NSMutableAttributedString {
        let string = NSMutableAttributedString(string: "Thanks for letting us know.", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 23), NSAttributedString.Key.foregroundColor: Theme.ultraDarkGray])
        string.append(NSAttributedString(string: "\n\n\nIf we find that this account is a problem to the Wikio Ki community, we will take action on it.\n\nBlocking the user is a way to improve your experience on Wikio Ki.", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: Theme.ultraDarkGray]))
        return string
    }
    
    private func contactUsLabelAttributedText() -> NSMutableAttributedString {
        let string = NSMutableAttributedString(string: "Feel free to contact us detailing more information about the report.", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: Theme.ultraDarkGray])
        return string
    }
    
    private func blockDetailsAttributedText() -> NSMutableAttributedString {
        var blockDetails: String!
        let isFriend = UserController.shared.currentUser?.friendsUids.contains(reportedUser.uid)
        if let _ = isFriend, isFriend! {
            blockDetails = "\(reportedUser.username) will be removed from your friends lists. You will be removed from their friends list. They are prevented from re-adding you as a friend. They are blocked from sending you posts."
        } else {
            blockDetails = "\(reportedUser.username) is prevented from adding you as a friend. They are blocked from sending you posts."
        }
        let string = NSMutableAttributedString(string: blockDetails, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: Theme.ultraDarkGray])
        return string
    }
    
    private func sendEmailReport(subject: String, body: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["teamwikioki@gmail.com"])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else {
            print("Can not send mail")
        }
    }
    
    private func emailBody(withReason reason: String) -> String {
        return "\(UserController.shared.currentUser!.username)(\(UserController.shared.currentUser!.uid)) is reporting \(reportedUser.username)(\(reportedUser.uid)) for \(reason)"
    }

}

extension ReportedViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Private Methods
import FirebaseFirestore
private extension ReportedViewController {
    func changeBestFriendStatus(isBestFriend: Bool, completion: @escaping ErrorCompletion) {
        let dbs = DatabaseService()
        let document = Firestore.firestore().collection(DatabaseService.Collection.users).document(UserController.shared.currentUser!.uid).collection(DatabaseService.Collection.friends).document(reportedUser.uid)
        
        dbs.updateDocument(document, withFields: ["isBestFriend": isBestFriend], completion: completion)
        
    }
}
