//
//  MessageImageDataSource.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class MessageImageDataSource: NSObject, UICollectionViewDataSource {
    var images: [UIImage] = []
    
    var onTapHandler: (([UIImage], Int) -> Void)?
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(images.count, 5)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item < images.count else {
            return UICollectionViewCell() 
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.description(), for: indexPath) as? ImageCell else {
            fatalError("Unable to dequeue ImageCell")
        }
        cell.configure(
            with: images[indexPath.item],
            allImages: images,
            index: indexPath.item
        )
        cell.onTap = onTapHandler

        return cell
    }
}
