//
//  ViewController.swift
//  SimpleChat
//
//  Created by sofiigorevna on 09.07.2025.
//

import UIKit

final class ChatViewController: UIViewController {
    private let webSocketManager = WebSocketManager()
    private var messages: [ChatItem] = []
    private var dataSource: UITableViewDiffableDataSource<Int, ChatItem>!
    
    private var inputContainerBottomConstraint: NSLayoutConstraint!
    
    private var activityIndicator = UIActivityIndicatorView()
    private var tableView = UITableView()
    private let dateOverlayLabel = UILabel()
    private let inputContainerView = MainInputContainerView()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(identifier: "Europe/Moscow")
        df.dateFormat = "HH:mm"
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        inputContainerView.delegate = self
        setupDataSource()
        
        setupKeyboard()
        webSocketManager.delegate = self
        webSocketManager.connect()
        loadMessages()
        updateSnapshot()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pressToSendFileMessage),
            name: Notification.Name("pressToSendFileMessage"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pressToSendMessage),
            name: Notification.Name("pressToSendMessage"),
            object: nil
        )
    }
    
    @objc private func pressToSendFileMessage(_ notification: Notification) {
        if let newMessage = notification.userInfo?["message"] as? Message {
            messages.append(.message(newMessage))
            updateSnapshot()
            activityIndicator.stopAnimating()
            saveMessages()
        }
    }
    
    @objc private func pressToSendMessage(_ notification: Notification) {
        if let newMessage = notification.userInfo?["message"] as? Message {
            if let text = newMessage.text,
               let selectedImages = newMessage.images {
                
                guard !text.isEmpty || !selectedImages.isEmpty else { return }
                let imagesData = selectedImages.compactMap { $0.pngData()}
                
                let newMessage = Message(
                    text: text,
                    timestamp: Date(),
                    isFromUser: true,
                    imagesData: imagesData
                )
                
                messages.append(.message(newMessage))
                updateSnapshot()
                webSocketManager.sendTextAndImage(text: text, imageData: imagesData)
                inputContainerView.prepare()
                saveMessages()
            }
        }
    }
    
    @objc private func sendMessage(text: String) {
        guard !text.isEmpty  else { return }
        
        let newMessage = Message(
            text: text,
            timestamp: Date(),
            isFromUser: true,
            imagesData: nil
        )
        
        messages.append(.message(newMessage))
        updateSnapshot()
        webSocketManager.sendTextAndImage(text: text, imageData: [])
        inputContainerView.prepare()
        saveMessages()
    }
    
    @objc private func setAttachmentFile() {
        presentAttachMenu()
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
    
    @objc private func handleScrollViewTap() {
        inputContainerView.handleTapOutside()
    }
}

// MARK: - UITextViewDelegate
extension ChatViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text as NSString
        let newText = currentText.replacingCharacters(in: range, with: text)
        return newText.count <= 100
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollToBottom()
    }
}
// MARK: - WebSocketManagerDelegate
extension ChatViewController: WebSocketManagerDelegate {
    func didReceiveContent(_ content: WebSocketContent) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            let now = Date()
            
            switch content {
                case .text(let text):
                    let newMessage = Message(text: text, timestamp: now, isFromUser: false)
                    self.messages.append(.message(newMessage))
                    
                case .image(let image):
                    let newMessage = Message(text: "", timestamp: now, isFromUser: false, imagesData: image)
                    
                    self.messages.append(.message(newMessage))
                    
                case .imageWithText(let text, let image):
                    let newMessage = Message(text: text, timestamp: now, isFromUser: false, imagesData: image)
                    
                    self.messages.append(.message(newMessage))
                    
                case .document(data: let data, fileName: let fileName, mimeType: let mimeType):
                    
                    let documentData = Document(data: data, fileName: fileName, mimeType: mimeType)
                    
                    let newMessage = Message(
                        text: "",
                        timestamp: Date(),
                        isFromUser: false,
                        imagesData: nil,
                        documentData: documentData
                    )
                    
                    messages.append(.message(newMessage))
            }
            
            self.updateSnapshot()
        }
    }
    
    func didEncounterError(_ error: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            let alert = UIAlertController(
                title: "Ошибка",
                message: error,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Повторить", style: .default) { _ in
                self.webSocketManager.connect()
            })
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate
extension ChatViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
// MARK: - setupView
private extension ChatViewController {
    func setupView() {
        setupNavBar()
        setupTableView()
        setapLabel()
        setupActivityIndicator()
        setupBackgroundImage()
        
        view.subviewsOnView(
            tableView,
            inputContainerView,
            activityIndicator,
            dateOverlayLabel)
        setupConstraints()
    }
    
    func setupNavBar() {
        navigationController?.navigationBar.isTranslucent = false
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        
        // 1. базовый шрифт
        let baseFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        
        // 2. Масштабируем его через UIFontMetrics (если нужно поддержать Dynamic Type)
        let scaledFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: baseFont)
        
        // 3. Применяем к заголовку
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: scaledFont
        ]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        title = "Чат"
    }
    
    func setupBackgroundImage() {
        let backgroundImage = UIImageView(frame: view.bounds)
        backgroundImage.image = UIImage(named: "background")
        backgroundImage.contentMode = .scaleAspectFill
        backgroundImage.clipsToBounds = true
        
        // Создаем основной черный фон
        let blackBackground = UIView(frame: view.bounds)
        blackBackground.backgroundColor = .black
        view.addSubview(blackBackground)
        
        // Добавляем изображение поверх черного фона
        view.addSubview(backgroundImage)
        backgroundImage.alpha = 0.8
        
        // Добавляем дополнительный overlay
        let overlay = UIView(frame: view.bounds)
        view.addSubview(overlay)
        
        // Убедимся, что все фоновые элементы находятся позади контента
        view.sendSubviewToBack(overlay)
        view.sendSubviewToBack(backgroundImage)
        view.sendSubviewToBack(blackBackground)
    }
    
    func setapLabel() {
        dateOverlayLabel.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.9)
        dateOverlayLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        dateOverlayLabel.textColor = .label
        dateOverlayLabel.textAlignment = .center
        dateOverlayLabel.layer.cornerRadius = 12
        dateOverlayLabel.layer.masksToBounds = true
        dateOverlayLabel.isHidden = true // сначала скрыта
    }
    
    func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .interactive
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.description())
        tableView.register(DateCell.self, forCellReuseIdentifier: DateCell.description())
        tableView.delegate = self
    }
    
    func setupActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.hidesWhenStopped = true
    }
    
    func setupDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, ChatItem>(tableView: tableView) { [weak self] tableView, indexPath, item in
            switch item {
                case .message(let message):
                    let cell = tableView.dequeueReusableCell(withIdentifier: MessageCell.description(), for: indexPath) as! MessageCell
                    cell.configure(with: message, dateFormatter: self?.dateFormatter ?? DateFormatter())
                   
                    cell.onImageSelected = { [weak self] images, index in
                        let vc = ImageItemViewController(imageURLs: images, initialIndex: index)
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                    cell.backgroundView?.backgroundColor = .clear
                    return cell
                case .date(let date):
                    let cell = tableView.dequeueReusableCell(withIdentifier: DateCell.description(), for: indexPath) as! DateCell
                    cell.configure(with: date)
                    return cell
            }
        }
        updateSnapshot()
    }
    
    func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatItem>()
        snapshot.appendSections([0])
        
        var result: [ChatItem] = []
        var lastDateComponent: DateComponents?
        
        for item in messages {
            guard case let .message(message) = item else { continue }
            
            let components = Calendar.current.dateComponents([.year, .month, .day], from: message.timestamp)
            
            if components != lastDateComponent {
                lastDateComponent = components
                result.append(.date(message.timestamp))
            }
            
            result.append(.message(message))
        }
        
        messages = result
        snapshot.appendItems(messages)
        
        dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
            self?.scrollToBottom()
        }
    }
    
    func scrollToBottom() {
        guard !messages.isEmpty,
              messages.count > 0,
              tableView.numberOfSections > 0,
              tableView.numberOfRows(inSection: 0) > 0 else {
            return
        }
        
        let indexPath = IndexPath(item: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScrollViewTap))
        tableView.addGestureRecognizer(tap)
    }
    
    // Сохранение сообщений
    func saveMessages() {
        let encoder = JSONEncoder()
        let onlyMessages = messages.compactMap { if case let .message(m) = $0 { return m } else { return nil } }
        if let encoded = try? encoder.encode(onlyMessages) {
            UserDefaults.standard.set(encoded, forKey: "chatMessages")
        }
    }
    // Загрузка сообщений
    func loadMessages() {
        do {
            if let savedData = UserDefaults.standard.data(forKey: "chatMessages") {
                let decoded = try JSONDecoder().decode([Message].self, from: savedData)
                messages = decoded.map { .message($0) }
                updateSnapshot()
            }
        } catch {
            print("Error loading messages: \(error)")
        }
        saveMessages()
    }
    
    func updateDateOverlay() {
        guard let indexPaths = tableView.indexPathsForVisibleRows,
              let first = indexPaths.min() else {
            dateOverlayLabel.isHidden = true
            return
        }
        
        let item = messages[first.row]
        guard case let .message(message) = item else {
            dateOverlayLabel.isHidden = true
            return
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(message.timestamp) {
            dateOverlayLabel.text = "Сегодня"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ru_RU")
            formatter.dateFormat = "d MMMM"
            dateOverlayLabel.text = formatter.string(from: message.timestamp)
        }
        dateOverlayLabel.isHidden = false
    }
}
// MARK: - Constraints
private extension ChatViewController {
    func setupConstraints() {
        [tableView, activityIndicator, dateOverlayLabel, inputContainerView].forEach { $0.tAMIC() }
        
        let bottomBackground = UIView()
        bottomBackground.backgroundColor = Colours.deepBlack.color
        bottomBackground.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(bottomBackground, belowSubview: inputContainerView)
        
        NSLayoutConstraint.activate([
            bottomBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBackground.topAnchor.constraint(equalTo: inputContainerView.topAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor),
        ])
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        inputContainerBottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            inputContainerBottomConstraint,
            inputContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            inputContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        NSLayoutConstraint.activate([
            dateOverlayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateOverlayLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            dateOverlayLabel.heightAnchor.constraint(equalToConstant: 24),
            dateOverlayLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
}

extension ChatViewController: AttachMenuViewControllerDelegate {
    func closeTappedDelegate() { }
    
    func sendMessageDelegate(text: String) {
        sendMessage(text: text)
    }
    
    func openFileDelegate() { }
    
    func openCameraDelegate() {}
    
    func loadGalleryViewDelegate() {
        presentAttachMenu()
    }
}
