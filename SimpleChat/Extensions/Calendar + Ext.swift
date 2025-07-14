//
//  Calendar + Ext.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import Foundation

extension Calendar {
    func dateOnly(from date: Date) -> Date {
        return self.startOfDay(for: date)
    }
}
