//
//  ImageZoomCollectionViewCell.swift
//  SimpleChat
//
//  Created by sofiigorevna on 23.07.2025.
//

import UIKit

final class ImageZoomCollectionViewCell: UICollectionViewCell {
    private let deepBlack: UIColor = Colours.deepBlack.color
    private let snowWhite: UIColor = .lightGray
    private let white: UIColor = .white

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ImageZoomCollectionViewCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension ImageZoomCollectionViewCell {
    private func setupView() {
        contentView.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.frame = contentView.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        scrollView.addSubview(imageView)
        imageView.frame = scrollView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.backgroundColor = self.deepBlack

        contentView.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = contentView.center
    }
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
    
    func configure(with imagePath: String) {
        activityIndicator.startAnimating()
        imageView.image = nil
      
        UIImage.loadImage(from: imagePath) { [weak self] image in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.imageView.image = image
                self.activityIndicator.stopAnimating()
            }
        }
    }
}
