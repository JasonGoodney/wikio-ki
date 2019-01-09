//
//  ViewMessagesViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit

class ViewMessagesViewController: UIViewController {
    private let cellId = ViewMessageCell.reuseIdentifier
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = self.view.frame.size
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.isPagingEnabled = true
        view.register(ViewMessageCell.self, forCellWithReuseIdentifier: cellId)
        return view
    }()
    
    private lazy var dismissGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer()
        gesture.addTarget(self, action: #selector(dismissTapped))
        return gesture
    }()
    
    private lazy var dismissBackButton: UIButton = {
        let button = UIButton()
        button.setImage(#imageLiteral(resourceName: "close"), for: .normal)
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        button.tintColor = .white
        button.addShadow()
        button.isHidden = true
        return button
    }()
    
    var indexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collectionView.reloadData()
        scrollToIndexPath()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func scrollToIndexPath() {
        guard let indexPath = indexPath else { return }
        DispatchQueue.main.async {
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    @objc func dismissTapped() {
        dismiss(animated: false)
    }
    
}

// MARK: - UI
private extension ViewMessagesViewController {
    func updateView() {
        view.addSubviews(collectionView, dismissBackButton)
        view.addGestureRecognizer(dismissGesture)
        view.backgroundColor = .white
        setupConstraints()
    }
    
    func setupConstraints() {
        collectionView.anchor(view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, topConstant: 0, leftConstant: 0, bottomConstant: 0, rightConstant: 0, widthConstant: 0, heightConstant: 0)
        
        dismissBackButton.anchor(view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, topConstant: 24, leftConstant: 16, bottomConstant: 0, rightConstant: 0, widthConstant: 36, heightConstant: 36)
    }
}

extension ViewMessagesViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return MessageController.shared.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ViewMessageCell
        
        let message = MessageController.shared.messages[indexPath.row]
        
        cell.configureProperties(with: message)
        
        return cell
    }
}

extension ViewMessagesViewController: UICollectionViewDelegate {
    
}
