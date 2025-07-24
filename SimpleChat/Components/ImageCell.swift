//
//  ImageCell.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class ImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    var onTap: (([UIImage], Int) -> Void)?
    
    private var images: [UIImage] = []
    private var index: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.contentView.isUserInteractionEnabled = true
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            imageView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
              contentView.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTap() {
        onTap?(images, index)
    }
    
    func configure(with image: UIImage, allImages: [UIImage], index: Int) {
        imageView.image = image
        self.images = allImages
        self.index = index
    }
}
