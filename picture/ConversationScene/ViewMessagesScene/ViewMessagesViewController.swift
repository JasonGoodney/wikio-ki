//
//  ViewMessagesViewController.swift
//  picture
//
//  Created by Jason Goodney on 12/17/18.
//  Copyright © 2018 Jason Goodney. All rights reserved.
//

import UIKit
import AVFoundation

class ViewMessagesViewController: UIViewController {
    private let cellId = ViewMessageCell.reuseIdentifier
    
    var visibleIP : IndexPath?
    
    var aboutToBecomeInvisibleCell = -1
    
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
        DispatchQueue.main.async {
            self.dismiss(animated: false)
        }
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
    func playVideoOnTheCell(cell : ViewMessageCell, indexPath : IndexPath){
        cell.startPlayback()
    }
    
    func stopPlayBack(cell : ViewMessageCell, indexPath : IndexPath){
        cell.stopPlayback()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("end = \(indexPath)")
        if let videoCell = cell as? ViewMessageCell {
            videoCell.stopPlayback()
        }
    }
}

extension ViewMessagesViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let indexPaths = self.collectionView.indexPathsForVisibleItems
        var cells = [Any]()
        for ip in indexPaths {
            if let videoCell = self.collectionView.cellForItem(at: ip) as? ViewMessageCell{
                cells.append(videoCell)
            }
        }
        let cellCount = cells.count
        if cellCount == 0 {return}
        if cellCount == 1{
            if visibleIP != indexPaths[0]{
                visibleIP = indexPaths[0]
            }
            if let videoCell = cells.last! as? ViewMessageCell{
                self.playVideoOnTheCell(cell: videoCell, indexPath: (indexPaths.last)!)
            }
        }
        if cellCount >= 2 {
            for i in 0..<cellCount{
                
                let cellRect = collectionView.frame // self.collectionView.rectForRow(at: (indexPaths?[i])!)
                let intersect = cellRect.intersection(self.collectionView.bounds)
                //                curerntHeight is the height of the cell that
                //                is visible
                let currentHeight = intersect.height
                print("\n \(currentHeight)")
                let cellHeight = (cells[i] as AnyObject).frame.size.height
                //                0.95 here denotes how much you want the cell to display
                //                for it to mark itself as visible,
                //                .95 denotes 95 percent,
                //                you can change the values accordingly
                if currentHeight > (cellHeight * 0.95){
                    if visibleIP != indexPaths[i]{
                        visibleIP = indexPaths[i]
                        print ("visible = \(indexPaths[i])")
                        if let videoCell = cells[i] as? ViewMessageCell{
                            self.playVideoOnTheCell(cell: videoCell, indexPath: (indexPaths[i]))
                        }
                    }
                }
                else{
                    if aboutToBecomeInvisibleCell != indexPaths[i].row{
                        aboutToBecomeInvisibleCell = (indexPaths[i].row)
                        if let videoCell = cells[i] as? ViewMessageCell{
                            self.stopPlayBack(cell: videoCell, indexPath: (indexPaths[i]))
                        }
                        
                    }
                }
            }
        }
    }
}
