//
//  AttachMenuView.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class TopBarView: UIView {
    private var albumButton = UIButton()
    private var selectedCountView = UIView()
    private var selectedCountLabel = UILabel()
    private let checkmarkIcon = UIImageView()
    private let topBar = UIView()
    private let closeButton = UIButton()
    
    weak var delegate: AttachMenuViewControllerDelegate?
    
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
    
    @objc private func closeTapped() {
        delegate?.closeTappedDelegate()
    }
    
    func toggleInput(isSelection: Bool, selectedCount: Int) {
        selectedCountView.isHidden = !isSelection
        if isSelection {
            selectedCountLabel.text = "\(selectedCount)"
        }
    }
    
    func albumButtonSetting(title: String) {
        self.albumButton.setTitle("\(title) ▼", for: .normal)
        self.albumButton.titleColor(for: .normal)
        self.albumButton.titleLabel?.textColor = .label
    }
    
    func albumButtonSettingMenu(title: String, actions: [UIAction]) {
        self.albumButton.menu = UIMenu(title:title, children: actions)
        self.albumButton.showsMenuAsPrimaryAction = true
        self.albumButton.titleLabel?.textColor = .label
    }
}

// MARK: - Setup
private extension TopBarView {
    func setupHierarchy() {
        self.backgroundColor = .systemBackground
        
        [topBar].forEach { view in
            self.addSubview(view)
        }
        setupTopBar()
        setupSelectedCountView()
        setupButtons()
    }
    
    func setupLayout() {
        [topBar, closeButton, selectedCountView, selectedCountLabel, checkmarkIcon].forEach { view in
            view.tAMIC()
        }
        
        NSLayoutConstraint.activate([
            albumButton.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            albumButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
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
            
            selectedCountLabel.leftAnchor.constraint(equalTo: checkmarkIcon.rightAnchor, constant: 4),
            selectedCountLabel.rightAnchor.constraint(equalTo: selectedCountView.rightAnchor, constant: -6),
            selectedCountLabel.centerYAnchor.constraint(equalTo: selectedCountView.centerYAnchor),
            
            selectedCountView.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    func setupTopBar() {
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.titleLabel?.textColor = .black
        closeButton.setTitleColor(.label, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 15)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        [closeButton, albumButton, selectedCountView].forEach { view in
            topBar.addSubview(view)
        }
    }
    
    func setupSelectedCountView() {
        selectedCountView.backgroundColor = .label
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
    
    func setupButtons() {
        albumButton.setTitle("Недавние", for: .normal)
        albumButton.showsMenuAsPrimaryAction = true
        albumButton.translatesAutoresizingMaskIntoConstraints = false
        albumButton.titleLabel?.textColor = .black
        albumButton.setTitleColor(.label, for: .normal)
        albumButton.titleLabel?.font = .systemFont(ofSize: 15)
    }
}
