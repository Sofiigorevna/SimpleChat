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
    private var bottomConstraint: NSLayoutConstraint!
    
    private var activityIndicator = UIActivityIndicatorView()
    private var tableView = UITableView()
    private let inputTextView = UITextView()
    private var sendButton = UIButton()
    private var attachmentButton = UIButton()
    private let dateOverlayLabel = UILabel()
    private let inputContainerView = UIView()
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(identifier: "Europe/Moscow")
        df.dateFormat = "HH:mm"
        return df
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        
        setupDataSource()
    
        setupKeyboard()
        setupInputObservers()
        webSocketManager.delegate = self
        webSocketManager.connect()
        
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMessages()
        updateSnapshot()
    }
    
    @objc private func pressToSendFileMessage(_ notification: Notification) {
        if let newMessage = notification.userInfo?["message"] as? Message {
            messages.append(.message(newMessage))
            updateSnapshot()
            activityIndicator.stopAnimating()
            handleTextChange()
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
                inputTextView.text = ""
                saveMessages()
                handleTextChange()
            }
        }
    }
    
    @objc private func handleTextChange() {
        let maxHeight: CGFloat = 100   // Максимальная высота поля ввода
        let minHeight: CGFloat = 40    // Минимальная высота поля ввода
        
        // Получаем ширину поля ввода.
        // Если ширина ещё не известна (например, при первом запуске), используем запасной вариант.
        let width = inputTextView.frame.width > 0
        ? inputTextView.frame.width
        : UIScreen.main.bounds.width - 100
        
        // Рассчитываем, какой размер (высоту) нужно занять, чтобы вместить весь текст,
        // при ширине, заданной выше, и неограниченной высоте.
        let size = inputTextView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        
        // Ограничиваем высоту поля минимальной и максимальной высотой.
        // Таким образом, поле не станет меньше 40 и не больше 100.
        let newHeight = min(max(size.height, minHeight), maxHeight)
        
        // Если высота текста больше максимума — включаем прокрутку.
        // Иначе — прокрутка выключена, поле расширяется.
        inputTextView.isScrollEnabled = size.height > maxHeight
        
        // Находим constraint высоты поля ввода и меняем его значение
        if let heightConstraint = inputTextView.constraints.first(where: { $0.firstAttribute == .height }) {
            heightConstraint.constant = newHeight
        }
        
        // Анимируем изменение layout, чтобы изменение высоты выглядело плавно.
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func sendMessage() {
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
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
        inputTextView.text = ""
        saveMessages()
        handleTextChange()
    }

    @objc private func setAttachmentFile() {
        presentAttachMenu()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard
            let userInfo = notification.userInfo,
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            bottomConstraint != nil
        else { return }
        
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        bottomConstraint.constant = -keyboardHeight
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            bottomConstraint != nil
        else { return }
        
        bottomConstraint.constant = 0
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func handleScrollViewTap() {
        inputTextView.becomeFirstResponder()
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
        setupTableView()
        setupInputTextView()
        setapLabel()
        setupButtons()
        setupActivityIndicator()
        
        view.subviewsOnView(tableView,inputContainerView, activityIndicator, dateOverlayLabel)
        inputContainerView.subviewsOnView(attachmentButton, inputTextView, sendButton)
        setupConstraints()
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
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .interactive
        tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.description())
        tableView.register(DateCell.self, forCellReuseIdentifier: DateCell.description())
        tableView.delegate = self
    }
    
    func setupInputTextView() {
        inputTextView.font = .systemFont(ofSize: 16)
        inputTextView.layer.cornerRadius = 14
        inputTextView.layer.borderWidth = 1
        inputTextView.layer.borderColor = UIColor.systemGray4.cgColor
        inputTextView.isScrollEnabled = false
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }
    
    func setupButtons() {
        let sendConfig = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)
        let sendIcon = UIImage(systemName: "arrowshape.up.circle.fill", withConfiguration: sendConfig)
        
        sendButton.setImage(sendIcon, for: .normal)
        sendButton.tintColor = .darkGray
        sendButton.backgroundColor = .clear
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .light)
        let paperclipIcon = UIImage(systemName: "paperclip", withConfiguration: config)
        attachmentButton.setImage(paperclipIcon, for: .normal)
        attachmentButton.tintColor = .darkGray
        attachmentButton.backgroundColor = .clear
        attachmentButton.addTarget(self, action: #selector(setAttachmentFile), for: .touchUpInside)
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
    
    func setupInputObservers() {
        inputTextView.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTextChange),
            name: UITextView.textDidChangeNotification,
            object: nil
        )
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
        [tableView, inputTextView, sendButton, activityIndicator, dateOverlayLabel, attachmentButton, inputContainerView].forEach { $0.tAMIC() }
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputTextView.topAnchor, constant: -8)
        ])
        
        bottomConstraint = inputContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            inputContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            inputContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            bottomConstraint,
            
            attachmentButton.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 16),
            attachmentButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            attachmentButton.widthAnchor.constraint(equalToConstant: 36),
            attachmentButton.heightAnchor.constraint(equalToConstant: 36),
            
            sendButton.rightAnchor.constraint(equalTo: inputContainerView.rightAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            
            inputTextView.leftAnchor.constraint(equalTo: attachmentButton.rightAnchor, constant: 8),
            inputTextView.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 12),
           // inputTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            dateOverlayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dateOverlayLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            dateOverlayLabel.heightAnchor.constraint(equalToConstant: 24),
            dateOverlayLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
}

extension ChatViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        loadMessages()
        updateSnapshot()
    }
}
