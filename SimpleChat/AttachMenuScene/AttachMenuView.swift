//
//  AttachMenuView.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class AttachMenuView: UIView {
    private var buttonStackView = UIStackView()
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private var albumButton = UIButton()
    private var selectedCountView = UIView()
    private var selectedCountLabel = UILabel()
    private let checkmarkIcon = UIImageView()
    
    private let topBar = UIView()
    private let closeButton = UIButton(type: .system)
    
    weak var delegate: AttachMenuViewControllerDelegate?
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate.self
        setupHierarchy()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Error in Cell")
    }
    
    @objc private func loadGalleryView() {
        delegate?.loadGalleryViewDelegate()
    }
    @objc private func sendMessage() {
        delegate?.sendMessageDelegate()
    }
    @objc private func closeTapped() {
        delegate?.closeTappedDelegate()
    }
    @objc private func openCamera() {
        delegate?.openCameraDelegate()
    }
    @objc private func openFile() {
        delegate?.openFileDelegate()
    }
    
    func toggleInput(isSelection: Bool, selectedCount: Int) {
        buttonStackView.isHidden = isSelection
        inputContainerView.isHidden = !isSelection
        
        selectedCountView.isHidden = !isSelection
            if isSelection {
                selectedCountLabel.text = "\(selectedCount)"
            }
    }
    
    func albumButtonSetting(title: String) {
        self.albumButton.setTitle("\(title) ▼", for: .normal)
    }
    
    func albumButtonSettingMenu(title: String, actions: [UIAction]) {
        self.albumButton.menu = UIMenu(title:title, children: actions)
        self.albumButton.showsMenuAsPrimaryAction = true
    }
}

// MARK: - Setup
private extension AttachMenuView {
    func setupHierarchy() {
        self.backgroundColor = .systemBackground
        
        [topBar, buttonStackView, inputContainerView].forEach { view in
            self.addSubview(view)
        }
        
        setupTopBar()
        setupAttachMenu()
        setupSelectedCountView()
        setupInputTextView()
        setupButtons()
    }
    
    func setupLayout() {
        [topBar, closeButton, selectedCountView, selectedCountLabel, checkmarkIcon, inputContainerView, inputTextView, sendButton].forEach { view in
            view.tAMIC()
        }
        
        NSLayoutConstraint.activate([
            albumButton.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            albumButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: self.topAnchor),
            topBar.leftAnchor.constraint(equalTo: self.leftAnchor),
            topBar.rightAnchor.constraint(equalTo: self.rightAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 50),
            
            closeButton.leftAnchor.constraint(equalTo: topBar.leftAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            selectedCountView.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            selectedCountView.rightAnchor.constraint(equalTo: topBar.rightAnchor, constant: -16),
            selectedCountView.heightAnchor.constraint(equalToConstant: 24),
            
            checkmarkIcon.leftAnchor.constraint(equalTo: selectedCountView.leftAnchor, constant: 6),
            checkmarkIcon.centerYAnchor.constraint(equalTo: selectedCountView.centerYAnchor),
            checkmarkIcon.widthAnchor.constraint(equalToConstant: 14),
            checkmarkIcon.heightAnchor.constraint(equalToConstant: 14),
            
            selectedCountLabel.leadingAnchor.constraint(equalTo: checkmarkIcon.rightAnchor, constant: 4),
            selectedCountLabel.rightAnchor.constraint(equalTo: selectedCountView.rightAnchor, constant: -6),
            selectedCountLabel.centerYAnchor.constraint(equalTo: selectedCountView.centerYAnchor),
            
            selectedCountView.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        NSLayoutConstraint.activate([
            buttonStackView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            buttonStackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            buttonStackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            inputContainerView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            inputContainerView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
            inputContainerView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
            inputContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            inputTextView.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 8),
            inputTextView.centerYAnchor.constraint(equalTo: inputContainerView.centerYAnchor),
            inputTextView.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.leftAnchor.constraint(equalTo: inputTextView.rightAnchor, constant: 8),
            sendButton.rightAnchor.constraint(equalTo: inputContainerView.rightAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: inputTextView.centerYAnchor),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            inputTextView.rightAnchor.constraint(lessThanOrEqualTo: sendButton.leftAnchor, constant: -8)
        ])
    }
    
    func setupTopBar() {
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        [closeButton, albumButton, selectedCountView].forEach { view in
            topBar.addSubview(view)
        }
    }
    
    func setupSelectedCountView() {
        selectedCountView.backgroundColor = .systemBlue
        selectedCountView.layer.cornerRadius = 12
        selectedCountView.isHidden = true
        
        selectedCountLabel.font = .systemFont(ofSize: 14, weight: .medium)
        selectedCountLabel.textColor = .white
        selectedCountLabel.textAlignment = .center
        
        checkmarkIcon.image = UIImage(systemName: "checkmark")
        checkmarkIcon.tintColor = .white
        checkmarkIcon.contentMode = .scaleAspectFit
        checkmarkIcon.frame = CGRect(x: 3, y: 3, width: 14, height: 14)
        
        [selectedCountLabel, checkmarkIcon].forEach { view in
            selectedCountView.addSubview(view)
        }
    }
    
    func setupAttachMenu() {
        buttonStackView.axis = .horizontal
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .center
        buttonStackView.spacing = 12
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let galleryButton = makeButton(title: "📷 Галерея", action: #selector(loadGalleryView))
        let cameraButton = makeButton(title: "📸 Камера", action: #selector(openCamera))
        let fileButton = makeButton(title: "📁 Файл", action: #selector(openFile))
        
        [galleryButton, cameraButton, fileButton].forEach { buttonStackView.addArrangedSubview($0) }
        
        inputContainerView.isHidden = true
        inputContainerView.backgroundColor = .clear
        
        [inputTextView, sendButton].forEach { view in
            inputContainerView.addSubview(view)
        }
    }
    
    func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = 12
        button.backgroundColor = .systemGray6
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
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
        
        albumButton.setTitle("Недавние", for: .normal)
        // albumButton.tintColor = .label
        albumButton.titleLabel?.textColor = .label
        albumButton.showsMenuAsPrimaryAction = true
        albumButton.translatesAutoresizingMaskIntoConstraints = false
    }
}
