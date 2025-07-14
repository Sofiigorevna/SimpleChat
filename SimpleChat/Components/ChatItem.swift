//
//  ChatItem.swift
//  SimpleChat
//
//  Created by sofiigorevna on 14.07.2025.
//

import UIKit

enum ChatItem: Hashable {
    case date(Date)
    case message(Message)
}

struct Message: Hashable {
    let id = UUID()
    let text: String?
    let timestamp: Date
    let isFromUser: Bool
    let imagesData: [Data]?   
    let documentData: Document?
    
    init(text: String?, timestamp: Date, isFromUser: Bool, imagesData: [Data]? = nil, documentData: Document? = nil) {
        self.text = text
        self.timestamp = timestamp
        self.isFromUser = isFromUser
        self.imagesData = imagesData
        self.documentData = documentData
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Чтобы получить UIImage из imageData:
    var images: [UIImage]? {
        return imagesData?.compactMap { UIImage(data: $0) }
    }
}

extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case text, timestamp, isFromUser, imagesData, documentData
    }
}

extension Message {
    var isImageOnly: Bool {
        text == nil && imagesData != nil
    }
    
    var isTextOnly: Bool {
        text != nil && imagesData == nil
    }
    
    var isTextAndImage: Bool {
        text != nil && imagesData != nil
    }
}

struct Document: Hashable, Codable {
        let data: Data
        let fileName: String
        let mimeType: String
    }
