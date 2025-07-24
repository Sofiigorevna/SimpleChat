//
//  ImageViewController.swift
//  SimpleChat
//
//  Created by sofiigorevna on 23.07.2025.
//

import UIKit

final class ImageItemViewController: UIViewController {
    private var activityIndicator = UIActivityIndicatorView()
    private var imageURLs: [UIImage]
    private var initialIndex: Int
    private let pagePadding: CGFloat = 10
    private var didSetInitialIndex = false // Флаг для предотвращения повторного выполнения
    
    private let primaryAccent = Colours.primaryAccent.color
    private let deepBlack: UIColor = Colours.deepBlack.color
    private let snowWhite: UIColor = Colours.white.color
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = snowWhite
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageZoomCollectionViewCell.self, forCellWithReuseIdentifier: ImageZoomCollectionViewCell.description())
        return collectionView
    }()
    
    init(imageURLs: [UIImage], initialIndex: Int = 0) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollToInitialIndexIfNeeded()
    }

    private func scrollToInitialIndexIfNeeded() {
        guard !didSetInitialIndex, initialIndex < imageURLs.count else { return }
        let indexPath = IndexPath(item: initialIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        didSetInitialIndex = true
    }

    func prepareForReuse() {
        collectionView.reloadData()
    }
    
    @objc private func pressToClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UICollectionViewDataSource
extension ImageItemViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageZoomCollectionViewCell.description(), for: indexPath) as! ImageZoomCollectionViewCell
        let url = imageURLs[indexPath.item]
        cell.configure(with: url)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

// MARK: - Private Methods
private extension ImageItemViewController {
    func setupView() {
        view.backgroundColor = deepBlack
        view.subviewsOnView(collectionView)
        setupCollectionView()
        setupConstraints()
    }

    func setupCollectionView() {
        collectionView.backgroundColor = .white
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ImageZoomCollectionViewCell.self, forCellWithReuseIdentifier: ImageZoomCollectionViewCell.description())
    }

    func setupConstraints() {
        [collectionView].forEach { $0.tAMIC() }

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}
