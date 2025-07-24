//
//  MainInputContainerView.swift
//  SimpleChat
//
//  Created by sofiigorevna on 23.07.2025.
//

import UIKit
// вынести в отдельную вью
final class MainInputContainerView: UIView {
    private let inputTextView = UITextView()
    private var sendButton = UIButton()
    private var attachmentButton = UIButton()
    private let inputContainerView = UIView()

    weak var delegate: AttachMenuViewControllerDelegate?
    
    func prepare() {
        inputTextView.text = ""
    }
    
    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Error in Cell")
    }
    
    @objc private func sendMessage() {
        let text = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    
        delegate?.sendMessageDelegate(text: text)
        inputTextView.text = ""
        handleTextChange()
    }
    
    @objc private func setAttachmentFile() {
        delegate?.loadGalleryViewDelegate()
    }
    
    @objc private func handleScrollViewTap() {
        inputTextView.becomeFirstResponder()
    }
    
     func handleTapOutside() {
        inputTextView.becomeFirstResponder()
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
        }
    }
}
// MARK: - Setup
private extension MainInputContainerView {
    func setupHierarchy() {
        self.backgroundColor = Colours.deepBlack.color
        self.addSubview(inputContainerView)
        inputContainerView.subviewsOnView(attachmentButton, inputTextView, sendButton)
        
        setupInputTextView()
        setupButtons()
        setupInputObservers()
    }
    
    func setupInputTextView() {
        inputContainerView.backgroundColor = Colours.deepBlack.color
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
        sendButton.tintColor = Colours.primaryAccent.color
        sendButton.backgroundColor = .clear
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .light)
        let paperclipIcon = UIImage(systemName: "paperclip", withConfiguration: config)
        attachmentButton.setImage(paperclipIcon, for: .normal)
        attachmentButton.tintColor = Colours.primaryAccent.color
        attachmentButton.backgroundColor = .clear
        attachmentButton.addTarget(self, action: #selector(setAttachmentFile), for: .touchUpInside)
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
    
    func setupLayout() {
        [inputTextView, sendButton, attachmentButton, inputContainerView].forEach { $0.tAMIC() }
    
        NSLayoutConstraint.activate([
            inputContainerView.topAnchor.constraint(equalTo: self.topAnchor),
            inputContainerView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16),
            inputContainerView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16),
            inputContainerView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            
            attachmentButton.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 8),
            attachmentButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            attachmentButton.widthAnchor.constraint(equalToConstant: 36),
            attachmentButton.heightAnchor.constraint(equalToConstant: 36),
            
            inputTextView.topAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: 10),
            inputTextView.leftAnchor.constraint(equalTo: attachmentButton.rightAnchor, constant: 8),
            inputTextView.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: -8),
            inputTextView.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -10),

            sendButton.rightAnchor.constraint(equalTo: inputContainerView.rightAnchor, constant: -8),
            sendButton.bottomAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: -12),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
}
// MARK: - UITextViewDelegate
extension MainInputContainerView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text as NSString
        let newText = currentText.replacingCharacters(in: range, with: text)
        return newText.count <= 100
    }
}
