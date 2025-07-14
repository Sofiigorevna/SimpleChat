//
//  AttachMenuViewController.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit
import PhotosUI
import MobileCoreServices

protocol AttachMenuViewControllerDelegate: AnyObject {
    func closeTappedDelegate()
    func sendMessageDelegate()
    func openFileDelegate()
    func openCameraDelegate()
    func loadGalleryViewDelegate()
}

final class AttachMenuViewController: UIViewController,   UINavigationControllerDelegate {
    
    private var imageAssets: [PHAsset] = []
    private var selectedIndexes: Set<IndexPath> = []
    private var collectionView: UICollectionView!
    private var attachMenuView = AttachMenuView()
    
    private let maxSelectionLimit = 5
    private var selectedImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupAttachMenuView()
        setupSystemAlbumsMenu()
        showGalleryGrid()
        loadGalleryView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        selectedImages.removeAll()
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendMessage() {

    }
    
    @objc private func openFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypeItem)], in: .import)
        documentPicker.delegate = self
        present(documentPicker, animated: true)
    }
    
    @objc private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        present(picker, animated: true)
    }
    
    @objc private func loadGalleryView() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self, status == .authorized || status == .limited else { return }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

            self.imageAssets = []
            assets.enumerateObjects { asset, _, _ in
                self.imageAssets.append(asset)
            }

            DispatchQueue.main.async {
                self.showGalleryGrid()
            }
        }
    }
}
// MARK: - AttachMenuViewControllerDelegate
extension AttachMenuViewController: AttachMenuViewControllerDelegate {
    func closeTappedDelegate() {
        self.closeTapped()
    }
    
    func sendMessageDelegate() {
        self.sendMessage()
    }
    
    func openFileDelegate() {
        self.openFile()
    }
    
    func openCameraDelegate() {
        self.openCamera()
    }
    
    func loadGalleryViewDelegate() {
        self.loadGalleryView()
    }
}

// MARK: - Setup
private extension AttachMenuViewController {
    func setupAttachMenuView() {
        view.addSubview(attachMenuView)
        attachMenuView.tAMIC()
        
        NSLayoutConstraint.activate([
            attachMenuView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            attachMenuView.leftAnchor.constraint(equalTo: view.leftAnchor),
            attachMenuView.rightAnchor.constraint(equalTo: view.rightAnchor),
            attachMenuView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }
    
    func showGalleryGrid() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        
        collectionView?.removeFromSuperview()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.description())
        
        collectionView.tAMIC()
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 44),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8)
        ])
    }
}
// MARK: - PHPhotoLibrary
private extension AttachMenuViewController {
    func setupSystemAlbumsMenu() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self, status == .authorized || status == .limited else { return }
            
            var actions: [UIAction] = []
            
            // Пример: "Недавние"
            if let recents = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
                let action = UIAction(title: recents.localizedTitle ?? "Недавние") { _ in
                    self.getPhotosFromAlbum(recents)
                }
                actions.append(action)
            }
            
            // "Избранное"
            if let favorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil).firstObject {
                let action = UIAction(title: favorites.localizedTitle ?? "Избранное") { _ in
                    self.getPhotosFromAlbum(favorites)
                }
                actions.append(action)
            }
            
            // Другие системные смарт-альбомы, например, можно перечислить нужные подтипы:
            let wantedSubtypes: [PHAssetCollectionSubtype] = [
                .smartAlbumSelfPortraits,
                .smartAlbumScreenshots,
                .smartAlbumPanoramas
            ]
            
            for subtype in wantedSubtypes {
                let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
                collections.enumerateObjects { collection, _, _ in
                    if let title = collection.localizedTitle {
                        let action = UIAction(title: title) { _ in
                            self.getPhotosFromAlbum(collection)
                        }
                        actions.append(action)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.attachMenuView.albumButtonSettingMenu(title: "Системные альбомы", actions: actions)
                if let firstAction = actions.first {
                    self.attachMenuView.albumButtonSetting(title: firstAction.title)
                    // Загрузить фото из первого альбома по умолчанию
                    if let firstCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
                        self.getPhotosFromAlbum(firstCollection)
                    }
                }
            }
        }
    }
    
    func getPhotosFromAlbum(_ album: PHAssetCollection) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        var newAssets: [PHAsset] = []
        assets.enumerateObjects { asset, _, _ in
            newAssets.append(asset)
        }
        
        
        DispatchQueue.main.async {
            self.imageAssets = newAssets
            self.selectedIndexes.removeAll()
            self.attachMenuView.albumButtonSetting(title: album.localizedTitle ?? "Альбом")
            self.collectionView.reloadData()
            self.toggleInputContainerView()
        }
    }
}
// MARK: - UICollectionViewDataSource
extension AttachMenuViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GalleryCell
        let asset = imageAssets[indexPath.item]
        cell.representedAssetIdentifier = asset.localIdentifier
        cell.setSelected(selectedIndexes.contains(indexPath))
        
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: 100, height: 100),
                                              contentMode: .aspectFill,
                                              options: nil) { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedIndexes.contains(indexPath) {
            selectedIndexes.remove(indexPath)
        } else {
            guard selectedIndexes.count < 5 else {
                let alert = UIAlertController(title: "Лимит", message: "Можно выбрать не более 5 изображений", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ОК", style: .default))
                present(alert, animated: true)
                return
            } // ограничение в 5 штук
            selectedIndexes.insert(indexPath)
        }
        collectionView.reloadItems(at: [indexPath])
        toggleInputContainerView()
    }
    
    func toggleInputContainerView() {
        let hasSelection = !selectedIndexes.isEmpty
        attachMenuView.toggleInput(isSelection: hasSelection, selectedCount: selectedIndexes.count)
    }
}
// MARK: - UIDocumentPickerDelegate
extension AttachMenuViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // handle picked file
    }
}
// MARK: - UIImagePickerControllerDelegate
extension AttachMenuViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            print("Снято фото: \(image)")
        }
    }
}

// MARK: - Entry Point from Paperclip Button
extension UIViewController {
    func presentAttachMenu() {
        let attachVC = AttachMenuViewController()
        attachVC.modalPresentationStyle = .pageSheet
        if let sheet = attachVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = false
        }
        present(attachVC, animated: true)
    }
}
