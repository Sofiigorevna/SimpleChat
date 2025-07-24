//
//  Ext+UIColor.swift
//  SimpleChat
//
//  Created by sofiigorevna on 24.07.2025.
//

import UIKit

extension UIColor {
    /**
        Удобный инициализатор для создания цвета UIColor на основе значений красного, зеленого, синего и альфа-канала.

        - Parameters:
            - red: Значение красного канала, от 0 до 255.
            - green: Значение зеленого канала, от 0 до 255.
            - blue: Значение синего канала, от 0 до 255.
            - alpha: Значение альфа-канала (прозрачности), от 0 до 255 (по умолчанию 255).

        - Returns: UIColor, созданный на основе указанных значений каналов.
    */
    convenience init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(alpha) / 255.0
        )
    }
    /**
        Удобный инициализатор для создания цвета UIColor на основе 24-битного целого числа в формате RGB.

        - Parameter hex: 24-битное целое число, представляющее цвет в формате RGB.

        - Returns: UIColor, созданный на основе указанного 24-битного целого числа.
    */
    convenience init(hex: Int) {
        if hex > 0xffffff {
            self.init(
                red: UInt8((hex >> 24) & 0xff),
                green: UInt8((hex >> 16) & 0xff),
                blue: UInt8((hex >> 8) & 0xff),
                alpha: UInt8(hex & 0xff)
            )
        } else {
            self.init(
                red: UInt8((hex >> 16) & 0xff),
                green: UInt8((hex >> 8) & 0xff),
                blue: UInt8(hex & 0xff)
            )
        }
    }
    /**
        Удобный инициализатор для создания цвета UIColor на основе строкового представления шестнадцатеричного числа.

        - Parameter hex: Строковое представление шестнадцатеричного числа, представляющее цвет в формате RGB.

        - Returns: UIColor, созданный на основе указанной строки шестнадцатеричного числа.
    */
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        let hex = UInt(hexSanitized, radix: 16) ?? 0
        
        self.init(hex: Int(hex))
    }
}
