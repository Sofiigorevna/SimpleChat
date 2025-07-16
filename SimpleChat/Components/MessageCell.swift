//
//  MessageCell.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class MessageCell: UITableViewCell {
    private var message: Message?
    
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private var imageCollectionView: UICollectionView!
    
    private let documentStackView = UIStackView()
    private let fileNameLabel = UILabel()
    private let iconDocument = UIImageView() //document.circle.fill
    private let mimeTypeLabel = UILabel()
    
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    private var imageOnlyConstraints: [NSLayoutConstraint] = []
    private var textOnlyConstraints: [NSLayoutConstraint] = []
    private var imageTextConstraints: [NSLayoutConstraint] = []
    private var documentOnlyConstraints: [NSLayoutConstraint] = []

    private var imageCollectionViewHeightConstraint: NSLayoutConstraint?
    private var imageCollectionViewWidthConstraint: NSLayoutConstraint?
    
    private var imageAspectRatioConstraint: NSLayoutConstraint?
    
    private var imageDataSource = MessageImageDataSource()
    
    var onReply: ((Message) -> Void)?
    var onDelete: ((Message) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        let interaction = UIContextMenuInteraction(delegate: self)
        addInteraction(interaction)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func documentTapped() {
        guard let message = message,
              let document = message.documentData else { return }

        let alert = UIAlertController(title: "Скачать документ?", message: document.fileName, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Скачать", style: .default, handler: { _ in
            self.presentSaveDocument(document)
        }))

        // Найти UIViewController и показать alert
        if let vc = self.parentViewController {
            vc.present(alert, animated: true)
        }
    }
    
    func configure(with message: Message, dateFormatter: DateFormatter) {
        self.message = message
        messageLabel.text = message.text
        timeLabel.text = dateFormatter.string(from: message.timestamp)
        checkFromUser(message.isFromUser)
        
        messageLabel.isHidden = true
        imageCollectionView.isHidden = true
        NSLayoutConstraint.deactivate(textOnlyConstraints + imageOnlyConstraints + imageTextConstraints)
        
        let images = message.images ?? []
        let imageCount = images.count
        
        if imageCount > 0 {
            imageCollectionView.isHidden = false
            imageDataSource.images = images
            imageCollectionView.collectionViewLayout = ChatImageLayoutProvider.makeLayout(for: imageCount)
            imageCollectionView.reloadData()
            
            imageAspectRatioConstraint?.isActive = false
            bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 350).isActive = true

            switch imageCount {
                case 1:
                    if let firstImage = images.first {
                        let aspectRatio = firstImage.size.width / firstImage.size.height
                        
                        let ratioConstraint = imageCollectionView.widthAnchor.constraint(equalTo: imageCollectionView.heightAnchor, multiplier: aspectRatio)
                        ratioConstraint.priority = .defaultHigh
                        ratioConstraint.isActive = true
                        imageAspectRatioConstraint = ratioConstraint
                        imageCollectionViewHeightConstraint?.constant = min(300, UIScreen.main.bounds.width / aspectRatio * 0.6)
                    }
                case 2:
                    let width: CGFloat = min(UIScreen.main.bounds.width * 0.8, 400)
                    let itemWidth = (width - 4) / 2
                    let itemHeight = itemWidth * 3 / 4
                    imageCollectionViewHeightConstraint?.constant = itemHeight
                    imageCollectionView.widthAnchor.constraint(equalToConstant: width).isActive = true
                case 3...5:
                    imageCollectionViewHeightConstraint?.constant = 220
                    imageCollectionView.widthAnchor.constraint(lessThanOrEqualToConstant: 400).isActive = true
                default:
                    imageCollectionViewHeightConstraint?.constant = 150
            }
        } else {
            bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 350).isActive = false
        }
        
        documentStackView.isHidden = true
        NSLayoutConstraint.deactivate(documentOnlyConstraints)

        if let document = message.documentData {
            fileNameLabel.text = document.fileName
            mimeTypeLabel.text = formattedFileSize(document.data)
            documentStackView.isHidden = false
            NSLayoutConstraint.activate(documentOnlyConstraints)
            return
        }
        
        switch (message.isTextOnly, message.isImageOnly, message.isTextAndImage) {
            case (true, false, false):
                messageLabel.isHidden = false
                NSLayoutConstraint.activate(textOnlyConstraints)
            case (false, true, false):
                imageCollectionView.isHidden = false
                NSLayoutConstraint.activate(imageOnlyConstraints)
            case (false, false, true):
                messageLabel.isHidden = false
                imageCollectionView.isHidden = false
                NSLayoutConstraint.activate(imageTextConstraints)
            default:
                break
        }
    }
}

private extension MessageCell {
    func setupView() {
        selectionStyle = .none
        setupLabels()
        setupBubbleView()
        setupImageCollectionView()
        setupDocumentView()
        
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        bubbleView.addSubview(timeLabel)
        bubbleView.addSubview(imageCollectionView)
        
        setupConstraints()
    }
    
    func setupLabels() {
        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)
        
        timeLabel.font = .systemFont(ofSize: 10)
       // timeLabel.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        timeLabel.textColor = .secondaryLabel
        timeLabel.textAlignment = .center
        timeLabel.layer.cornerRadius = 8
        timeLabel.layer.masksToBounds = true
    }
    
    func setupBubbleView() {
        bubbleView.layer.cornerRadius = 14
        bubbleView.clipsToBounds = true
    }
    
    func setupImageCollectionView() {
        let layout = ChatImageLayoutProvider.makeLayout(for: 0)
        imageCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        imageCollectionView.isScrollEnabled = false
        imageCollectionView.backgroundColor = .clear
        imageCollectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.description())
        imageCollectionView.dataSource = imageDataSource
        imageCollectionView.contentInset = .zero
        imageCollectionView.layoutMargins = .zero
    }
    
    func setupDocumentView() {
        iconDocument.translatesAutoresizingMaskIntoConstraints = false
        iconDocument.contentMode = .scaleAspectFit
        iconDocument.image = UIImage(systemName: "doc.circle.fill")
        iconDocument.tintColor = .darkGray
//        iconDocument.backgroundColor = .white
        iconDocument.setContentHuggingPriority(.required, for: .horizontal)

        fileNameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        fileNameLabel.numberOfLines = 1
        fileNameLabel.lineBreakMode = .byTruncatingMiddle
        fileNameLabel.adjustsFontSizeToFitWidth = false
        fileNameLabel.minimumScaleFactor = 1.0

        mimeTypeLabel.font = .systemFont(ofSize: 12)
        mimeTypeLabel.textColor = .secondaryLabel

        let labelsStack = UIStackView(arrangedSubviews: [fileNameLabel, mimeTypeLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2

        documentStackView.axis = .horizontal
        documentStackView.spacing = 8
        documentStackView.alignment = .center
        documentStackView.translatesAutoresizingMaskIntoConstraints = false
        documentStackView.addArrangedSubview(iconDocument)
        documentStackView.addArrangedSubview(labelsStack)

        documentStackView.isHidden = true
        bubbleView.addSubview(documentStackView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(documentTapped))
        documentStackView.isUserInteractionEnabled = true
        documentStackView.addGestureRecognizer(tapGesture)
    }

    func checkFromUser(_ isUser: Bool) {
        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false
        
        if isUser {
            bubbleView.backgroundColor = .systemGreen
            messageLabel.textColor = .white
            timeLabel.textAlignment = .right
            
            trailingConstraint = bubbleView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16)
            leadingConstraint = bubbleView.leftAnchor.constraint(greaterThanOrEqualTo: contentView.leftAnchor, constant: 60)
        } else {
            bubbleView.backgroundColor = .systemGray5
            messageLabel.textColor = .black
            timeLabel.textAlignment = .right
            
            leadingConstraint = bubbleView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16)
            trailingConstraint = bubbleView.rightAnchor.constraint(lessThanOrEqualTo: contentView.rightAnchor, constant: -60)
        }
        
        leadingConstraint?.isActive = true
        trailingConstraint?.isActive = true
    }
    
     func presentSaveDocument(_ document: Document) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        
        do {
            try document.data.write(to: tempURL)

            let picker = UIDocumentPickerViewController(forExporting: [tempURL])
            picker.modalPresentationStyle = .formSheet
            
            if let vc = self.parentViewController {
                vc.present(picker, animated: true)
            }
        } catch {
            print("Ошибка при создании файла: \(error.localizedDescription)")
        }
    }

    func formattedFileSize(_ data: Data) -> String {
        let size = Double(data.count)
        if size < 1024 {
            return String(format: "%.0f байт", size)
        } else if size < 1024 * 1024 {
            return String(format: "%.1f КБ", size / 1024)
        } else {
            return String(format: "%.2f МБ", size / (1024 * 1024))
        }
    }
    
    func setupConstraints() {
        [bubbleView, messageLabel, timeLabel, imageCollectionView, documentStackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        imageCollectionViewHeightConstraint = imageCollectionView.heightAnchor.constraint(equalToConstant: 0)
        imageCollectionViewHeightConstraint?.isActive = true
        
        imageCollectionViewWidthConstraint = imageCollectionView.widthAnchor.constraint(lessThanOrEqualToConstant: 400)
        imageCollectionViewWidthConstraint?.isActive = true
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
        
        textOnlyConstraints = [
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12),
            messageLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -12),

            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            timeLabel.rightAnchor.constraint(equalTo: messageLabel.rightAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ]
        
        imageOnlyConstraints = [
            
            imageCollectionView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 2),
            imageCollectionView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 2),
            imageCollectionView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -2),
            
            timeLabel.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 4),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            timeLabel.rightAnchor.constraint(equalTo: imageCollectionView.rightAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ]
        
        imageTextConstraints = [
            imageCollectionView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 2),
            imageCollectionView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 2),
            imageCollectionView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -2),
            
            messageLabel.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: 8),
            messageLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12),
            messageLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -12),
            
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 4),
            timeLabel.rightAnchor.constraint(equalTo: messageLabel.rightAnchor),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ]
    
        documentOnlyConstraints = [
            documentStackView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            documentStackView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 12),
            documentStackView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -12),
            
            iconDocument.widthAnchor.constraint(equalToConstant: 38),
            iconDocument.heightAnchor.constraint(equalToConstant: 38),
            
            timeLabel.topAnchor.constraint(equalTo: documentStackView.bottomAnchor, constant: 4),
            timeLabel.rightAnchor.constraint(equalTo: documentStackView.rightAnchor),
            timeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8)
        ]
    }
}

extension MessageCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let copy = UIAction(title: "Копировать", image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.string = self.message?.text
            }
            
            let reply = UIAction(title: "Ответить", image: UIImage(systemName: "arrowshape.turn.up.left")) { _ in
                if let message = self.message {
                    self.onReply?(message)
                }
            }
            
            let delete = UIAction(title: "Удалить", image: UIImage(systemName: "trash"), attributes: .destructive) { _ in
                if let message = self.message {
                    self.onDelete?(message)
                }
            }
            
            return UIMenu(title: "", children: [reply, copy, delete])
        }
    }
}
