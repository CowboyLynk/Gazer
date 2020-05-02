//
//  VideoViewCollection.swift
//  GazeAR
//
//  Created by Cowboy Lynk on 4/26/20.
//  Copyright © 2020 Cowboy Lynk. All rights reserved.
//

import Foundation
import UIKit

class VideoCell: UICollectionViewCell {

    static var identifier: String = "Cell"
    var uid: UInt = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.backgroundColor = UIColor.systemGray4
        self.contentView.layer.borderColor = UIColor.systemBlue.cgColor
        self.contentView.layer.borderWidth = 0
        self.contentView.layer.cornerRadius = 15
        self.contentView.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func update(videoView: UIView) {
        videoView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(videoView)
        NSLayoutConstraint.activate([
            videoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            videoView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            videoView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        self.uid = UInt(videoView.tag)
    }
    
    func changeBorder(shouldHighlight: Bool) {
        if shouldHighlight {
            self.contentView.layer.borderWidth = 10
        } else {
            self.contentView.layer.borderWidth = 0
        }
    }
}

extension VideoCallController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return self.data.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell
        let data = self.data[indexPath.item]
        cell.update(videoView: data)
        return cell
    }
    
    func newUserJoined(withView videoView: UIView) {
        data.append(videoView)
        collectionView.reloadData()
    }
}

extension VideoCallController: UICollectionViewDelegateFlowLayout {
    
    func getItemSize() -> CGFloat {
        var columns = data.count
        if columns >= 3 {
            columns = 2
        }
        return collectionView.bounds.width / CGFloat(columns) - 20
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let size = getItemSize()
        return CGSize(width: size, height: size)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let numItems = data.count
        var sideInset: CGFloat = 10
        if numItems == 2 {
            sideInset = (collectionView.bounds.height - getItemSize())/2
        } else if numItems >= 3 {
            sideInset = (collectionView.bounds.height - 2*getItemSize() - 10)/2
        }
        return UIEdgeInsets(top: sideInset, left: 10, bottom: sideInset, right: 10) //.zero
    }
}
