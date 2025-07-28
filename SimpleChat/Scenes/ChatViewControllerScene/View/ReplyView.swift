//
//  ReplyView.swift
//  SimpleChat
//
//  Created by sofiigorevna on 28.07.2025.
//

import UIKit

final class ReplyView: UIView {
    
    // MARK: - UI Elements
    private let verticalLine: UIView = {
        let view = UIView()
        view.backgroundColor = Colours.darkBlue.color
        view.layer.cornerRadius = 1
        return view
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()
    
    private let senderLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let messagePreviewLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let previewImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 4
        imageView.clipsToBounds = true
        imageView.isHidden = true
        return imageView
    }()
    
    private let replyCloseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = Colours.primaryAccent.color
        return button
    }()
    
    private let horizontalStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    // MARK: - Properties
    var onClose: (() -> Void)?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupHierarchy()
        setupLayout()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    func configure(with message: Message) {
        senderLabel.text = message.isFromUser ? "Вы" : "Помощник чата"
        
        // Настройка превью текста
        if let text = message.text, !text.isEmpty {
            messagePreviewLabel.text = String(text.prefix(30)) + (text.count > 30 ? "..." : "")
        } else {
            messagePreviewLabel.text = "Изображение"
        }
        
        // Настройка превью изображения
        if let firstImageData = message.imagesData?.first,
           let image = UIImage(data: firstImageData) {
            previewImageView.image = image
            previewImageView.isHidden = false
        } else {
            previewImageView.isHidden = true
        }
    }
}

// MARK: - Setup
private extension ReplyView {
    func setupView() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 8
    }
    
    func setupHierarchy() {
        contentStack.addArrangedSubview(senderLabel)
        contentStack.addArrangedSubview(messagePreviewLabel)
        
        horizontalStack.addArrangedSubview(verticalLine)
        horizontalStack.addArrangedSubview(previewImageView)
        horizontalStack.addArrangedSubview(contentStack)
        horizontalStack.addArrangedSubview(replyCloseButton)
        
        addSubview(horizontalStack)
    }
    
    func setupLayout() {
        [verticalLine, previewImageView, contentStack, replyCloseButton, horizontalStack].forEach {
            $0.tAMIC()
        }
        
        NSLayoutConstraint.activate([
            // Горизонтальный стек
            horizontalStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // Вертикальная линия
            verticalLine.widthAnchor.constraint(equalToConstant: 2),
            verticalLine.heightAnchor.constraint(equalTo: horizontalStack.heightAnchor),
            
            // Превью изображения
            previewImageView.widthAnchor.constraint(equalToConstant: 24),
            previewImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Кнопка закрытия
            replyCloseButton.widthAnchor.constraint(equalToConstant: 20),
            replyCloseButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    func setupActions() {
        replyCloseButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    @objc func closeButtonTapped() {
        onClose?()
    }
}
