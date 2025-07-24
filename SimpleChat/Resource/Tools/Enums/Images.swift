//
//  Images.swift
//  SimpleChat
//
//  Created by sofiigorevna on 23.07.2025.
//

import UIKit
/// Перечисление изображений находящихся в ассетах или системные иконки
enum Images: String {
    case emptyImage = "emptyImage"
    
    var image: UIImage? {
        if let image = UIImage(systemName: self.rawValue) {
            return image
        } else {
            return UIImage(systemName: Images.emptyImage.rawValue)
        }
    }
}
