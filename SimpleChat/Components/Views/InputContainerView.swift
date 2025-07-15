//
//  InputContainerView.swift
//  SimpleChat
//
//  Created by sofiigorevna on 15.07.2025.
//

import UIKit

final class InputContainerView: UIView {
    private var buttonStackView = UIStackView()
    private let inputContainerView = UIView()
    private let inputTextView = UITextView()
    private let sendButton = UIButton(type: .system)
    private var maxHeightConstraint: NSLayoutConstraint?

    weak var delegate: AttachMenuViewControllerDelegate?
    var onHeightChanged: (() -> Void)?

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    
        delegate?.sendMessageDelegate(text: text)
        inputTextView.text = ""
        handleTextChange()
    }
    
    @objc private func openCamera() {
        delegate?.openCameraDelegate()
    }
    @objc private func openFile() {
        delegate?.openFileDelegate()
    }
    
    @objc private func handleScrollViewTap() {
        inputTextView.becomeFirstResponder()
    }
    
    @objc private func handleTapOutside() {
        inputTextView.becomeFirstResponder()
        self.endEditing(true)
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
            self.layoutIfNeeded()
            self.onHeightChanged?()
        }
    }
    
    func toggleInput(isSelection: Bool) {
        buttonStackView.isHidden = isSelection
        inputContainerView.isHidden = !isSelection
    }
    
    func setMaxHeight(_ height: CGFloat) {
        maxHeightConstraint?.isActive = false
        maxHeightConstraint = heightAnchor.constraint(lessThanOrEqualToConstant: height)
        maxHeightConstraint?.priority = .required
        maxHeightConstraint?.isActive = true
    }
}

// MARK: - Setup
private extension InputContainerView {
    func setupHierarchy() {
        self.backgroundColor = .systemBackground
        [buttonStackView, inputContainerView].forEach { view in
            self.addSubview(view)
        }
        setupAttachMenu()
        setupInputTextView()
        setupButtons()
        setupInputObservers()
    }
    
    func setupLayout() {
        [inputContainerView, inputTextView, sendButton].forEach { view in
            view.tAMIC()
        }
      
        NSLayoutConstraint.activate([
            buttonStackView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            buttonStackView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            buttonStackView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
            buttonStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            inputContainerView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            inputContainerView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
            inputContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
             inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            inputTextView.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 8),
            inputTextView.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8),
            
            sendButton.rightAnchor.constraint(equalTo: inputContainerView.rightAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -8),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
            sendButton.widthAnchor.constraint(equalToConstant: 36)
        ])
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
        
        [inputTextView, sendButton].forEach { view in
            inputContainerView.addSubview(view)
        }
    }
    
    func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton()
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)

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
    }
}

// MARK: - UITextViewDelegate
extension InputContainerView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text as NSString
        let newText = currentText.replacingCharacters(in: range, with: text)
        return newText.count <= 100
    }
}
