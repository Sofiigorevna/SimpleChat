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
    func sendMessageDelegate(text: String)
    func openFileDelegate()
    func openCameraDelegate()
    func loadGalleryViewDelegate()
}

final class AttachMenuViewController: UIViewController,   UINavigationControllerDelegate {
    
    private let webSocketManager = WebSocketManager()
    private var imageAssets: [PHAsset] = []
    private var selectedIndexes: Set<IndexPath> = []
    private var collectionView: UICollectionView!
    private var topBarView = TopBarView()
    
    private let inputContainerView = InputContainerView()
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    
    private let maxSelectionLimit = 5
    private var selectedImages = [UIImage]()
    private var selectedImagesMap = [IndexPath: UIImage]()
    
    private var newMessage: Message?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        topBarView.delegate = self
        inputContainerView.delegate = self
        
        setupAttachMenuView()
        setupInputContainerView()
        showGalleryGrid()
        setupKeyboard()
        
        loadGalleryView()
        setupSystemAlbumsMenu()
        webSocketManager.delegate = self
        webSocketManager.connect()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        selectedImages.removeAll()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sendMessage() {
        guard let newMessage = newMessage else { return }
        
        pressToSendMessage(message: newMessage)
        dismiss(animated: true)
        self.newMessage = nil
    }
    
    func pressToSendMessage(message: Message) {
        NotificationCenter.default.post(
            name: Notification.Name("pressToSendMessage"),
            object: nil,
            userInfo: [
                "message": message
            ]
        )
    }
    
    func pressToSendFileMessage(message: Message) {
        NotificationCenter.default.post(
            name: Notification.Name("pressToSendFileMessage"),
            object: nil,
            userInfo: [
                "message": message
            ]
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            inputContainerBottomConstraint != nil
        else { return }
        
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        inputContainerBottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            inputContainerBottomConstraint != nil
        else { return }
        
        inputContainerBottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func openFile() {
        presentDocumentPicker()
    }
    
    @objc private func openCamera() {
        presentCameraPicker()
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
    
    func sendMessageDelegate(text: String) {
        guard !text.isEmpty || !selectedImages.isEmpty else {
            return
        }
        
        let imagesData = selectedImages.compactMap { $0.pngData() }
        
        newMessage = Message(
            text: text,
            timestamp: Date(),
            isFromUser: true,
            imagesData: imagesData
        )
        
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
        view.addSubview(topBarView)
        topBarView.tAMIC()
        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBarView.leftAnchor.constraint(equalTo: view.leftAnchor),
            topBarView.rightAnchor.constraint(equalTo: view.rightAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    func setupInputContainerView() {
        view.addSubview(inputContainerView)
        inputContainerView.tAMIC()
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)

        NSLayoutConstraint.activate([
            inputContainerBottomConstraint,
            inputContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            inputContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        view.bringSubviewToFront(inputContainerView)
    }
    
    func showGalleryGrid() {
        let spacing: CGFloat = 1
        let itemsPerRow: CGFloat = 3
        
        let totalSpacing = spacing * (itemsPerRow - 1)
        let sideInsets: CGFloat = 8 * 2 // left + right
        let screenWidth = UIScreen.main.bounds.width
        let itemWidth = floor((screenWidth - totalSpacing - sideInsets) / itemsPerRow)
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        
        collectionView?.removeFromSuperview()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GalleryCell.self, forCellWithReuseIdentifier: GalleryCell.description())
        
        collectionView.tAMIC()
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            collectionView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            collectionView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            collectionView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8)
        ])
    }
    
    func setupKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
}
// MARK: - PHPhotoLibrary
private extension AttachMenuViewController {
    func setupSystemAlbumsMenu() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self, status == .authorized || status == .limited else { return }
            
            var actions: [UIAction] = []
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            
            // Пример: "Недавние"
            if let recents = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
                let assets = PHAsset.fetchAssets(in: recents, options: fetchOptions)
                if assets.count > 0 {
                    let action = UIAction(title: "Недавние") { _ in
                        self.getPhotosFromAlbum(recents)
                    }
                    actions.append(action)
                }
            }
            
            // "Избранное"
            if let favorites = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: nil).firstObject {
                let assets = PHAsset.fetchAssets(in: favorites, options: fetchOptions)
                if assets.count > 0 {
                    let action = UIAction(title: "Избранное") { _ in
                        self.getPhotosFromAlbum(favorites)
                    }
                    actions.append(action)
                }
            }
            
            // Другие системные альбомы
            let wantedSubtypes: [PHAssetCollectionSubtype] = [
                .smartAlbumSelfPortraits,
                .smartAlbumScreenshots,
                .smartAlbumPanoramas
            ]
            
            for subtype in wantedSubtypes {
                let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
                collections.enumerateObjects { collection, _, _ in
                    let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    if assets.count > 0 {
                        if let title = collection.localizedTitle {
                            let action = UIAction(title: title) { _ in
                                self.getPhotosFromAlbum(collection)
                            }
                            actions.append(action)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.topBarView.albumButtonSettingMenu(title: "Системные альбомы", actions: actions)
                if let firstAction = actions.first {
                    self.topBarView.albumButtonSetting(title: firstAction.title)
                    // Загрузить фото из первого непустого альбома по умолчанию
                    if let firstCollection = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject {
                        let assets = PHAsset.fetchAssets(in: firstCollection, options: fetchOptions)
                        if assets.count > 0 {
                            self.getPhotosFromAlbum(firstCollection)
                        } else if let firstNonEmptyCollection = actions.compactMap({ action -> PHAssetCollection? in
                            return nil
                        }).first {
                            self.getPhotosFromAlbum(firstNonEmptyCollection)
                        }
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
            self.topBarView.albumButtonSetting(title: album.localizedTitle ?? "Альбом")
            self.collectionView.reloadData()
            self.toggleInputContainerView()
        }
    }
}
// MARK: - UIScrollViewDelegate
extension AttachMenuViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        inputContainerView.endEditing(true)
    }
}
// MARK: - UICollectionViewDataSource
extension AttachMenuViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCell.description(), for: indexPath) as! GalleryCell
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
        let asset = imageAssets[indexPath.item]
        
        if selectedIndexes.contains(indexPath) {
            selectedIndexes.remove(indexPath)
            selectedImagesMap.removeValue(forKey: indexPath)
        } else {
            guard selectedIndexes.count < 5 else {
                let alert = UIAlertController(title: "Лимит", message: "Можно выбрать не более 5 изображений", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ОК", style: .default))
                present(alert, animated: true)
                return
            }
            
            selectedIndexes.insert(indexPath)
            
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: PHImageManagerMaximumSize,
                                                  contentMode: .aspectFill,
                                                  options: nil) { [weak self] image, _ in
                guard let self = self, let image = image else { return }
                self.selectedImagesMap[indexPath] = image
                self.selectedImages = Array(self.selectedImagesMap.values)
            }
        }
        
        collectionView.reloadItems(at: [indexPath])
        toggleInputContainerView()
    }
    
    func toggleInputContainerView() {
        let hasSelection = !selectedIndexes.isEmpty
        inputContainerView.toggleInput(isSelection: hasSelection)
        topBarView.toggleInput(isSelection: hasSelection, selectedCount: selectedIndexes.count)
    }
}
// MARK: - UIDocumentPickerDelegate
extension AttachMenuViewController: UIDocumentPickerDelegate {
    func presentDocumentPicker() {
        // Выбор типов документов (например, все виды файлов)
        let supportedTypes: [UTType] = [UTType.item]
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false // или true, если нужно
        
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        do {
            let docData = try Data(contentsOf: selectedFileURL)
            let content = WebSocketContent.document(
                data: docData,
                fileName: selectedFileURL.lastPathComponent,
                mimeType: mimeType(for: selectedFileURL)
            )
            webSocketManager.send(content: content)
            
            let documentData = Document(data: docData, fileName: selectedFileURL.lastPathComponent, mimeType: mimeType(for: selectedFileURL))
            
            let newMessage = Message(
                text: "",
                timestamp: Date(),
                isFromUser: true,
                imagesData: nil,
                documentData: documentData
            )
            
            pressToSendFileMessage(message: newMessage)
            self.closeTapped()
        } catch {
            print("Ошибка при чтении файла: \(error.localizedDescription)")
            showFileReadErrorAlert(error: error)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Выбор файла отменён")
    }
    
    func mimeType(for url: URL) -> String {
        let ext = url.pathExtension
        guard let utType = UTType(filenameExtension: ext),
              let mimeType = utType.preferredMIMEType else {
            return "application/octet-stream"
        }
        return mimeType
    }
    
    func showFileReadErrorAlert(error: Error) {
        let alert = UIAlertController(
            title: "Ошибка",
            message: "Не удалось прочитать файл: \(error.localizedDescription)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate (Camera)
extension AttachMenuViewController: UIImagePickerControllerDelegate {
    func presentCameraPicker() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
            case .authorized:
                // Доступ к камере уже предоставлен, открываем камеру
                showCameraPicker()
            case .notDetermined:
                // Запрос разрешения на использование камеры
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            self.showCameraPicker()
                        } else {
                            self.showCameraPermissionDeniedAlert()
                        }
                    }
                }
            case .denied, .restricted:
                // Доступ к камере запрещён, показываем алерт с предложением изменить настройки
                showCameraPermissionDeniedAlert()
            @unknown default:
                break
        }
    }
    
    /// Метод для открытия камеры
    func showCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true)
    }
    
    /// Метод для показа алерта при отсутствии разрешения
    func showCameraPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: SettingsGallery.accessIsDeniedCameraTitle,
            message: SettingsGallery.accessIsDeniedCameraMessage,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: SettingsGallery.settingsTitleButton, style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: SettingsGallery.cancelTitleButton, style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        guard let image = info[.originalImage] as? UIImage, let _ = image.pngData() else {
            return
        }
        if selectedImages.count < maxSelectionLimit {
            self.selectedImages = [image]
        } else {
            showLimitExceededAlert()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
// MARK: - Private methods
private extension AttachMenuViewController {
    func showLimitExceededAlert() {
        let alertController = UIAlertController(
            title: SettingsGallery.attentionTitleButton,
            message: SettingsGallery.faildPhotoLimit10,
            preferredStyle: .alert
        )
        
        // Кнопка "Отмена"
        alertController.addAction(UIAlertAction(title: SettingsGallery.cancelTitleButton, style: .cancel))
        
        // Кнопка "Понятно"
        alertController.addAction(UIAlertAction(title: SettingsGallery.clearTitleButton, style: .default))
        
        // Показываем alert
        self.present(alertController, animated: true)
    }
    
    func isImageDuplicate(_ image: UIImage) -> Bool {
        for selectedImage in selectedImages {
            if selectedImage.pngData() == image.pngData() {
                return true
            }
        }
        return false
    }
}
// MARK: - WebSocketManagerDelegate
extension AttachMenuViewController: WebSocketManagerDelegate {
    
    func didReceiveContent(_ message: WebSocketContent) { }
    
    func didEncounterError(_ error: String) { }
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
