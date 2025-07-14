//
//  GalleryCell.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class GalleryCell: UICollectionViewCell {
    let imageView = UIImageView()
    let checkmark = UIView()
    let checkmarkIcon = UIImageView()
    var representedAssetIdentifier: String?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        imageView.frame = contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        checkmark.frame = CGRect(x: contentView.bounds.width - 24, y: 4, width: 20, height: 20)
        checkmark.layer.cornerRadius = 10
        checkmark.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        checkmark.layer.borderWidth = 2
        checkmark.layer.borderColor = UIColor.white.cgColor
        checkmark.isHidden = true
        contentView.addSubview(checkmark)

        checkmarkIcon.image = UIImage(systemName: "checkmark")
        checkmarkIcon.tintColor = .white
        checkmarkIcon.contentMode = .scaleAspectFit
        checkmarkIcon.frame = CGRect(x: 3, y: 3, width: 14, height: 14)
        checkmark.addSubview(checkmarkIcon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(_ selected: Bool) {
        checkmark.isHidden = !selected
    }
}
