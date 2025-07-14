//
//  DateCell.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

final class DateCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.9)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 8),
            label.heightAnchor.constraint(equalToConstant: 24),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])

        selectionStyle = .none
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        
        if Calendar.current.isDateInToday(date) {
            label.text = "Сегодня"
        } else {
            formatter.dateFormat = "d MMMM"
            label.text = formatter.string(from: date)
        }
    }
}

