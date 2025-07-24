//
//  ImageCache.swift
//  SimpleChat
//
//  Created by sofiigorevna on 23.07.2025.
//

import UIKit
/// Класс ImageCache предоставляет простой кэш для хранения изображений.
/// Он использует NSCache для кэширования изображений в памяти.
final class ImageCache {
    /// Общий экземпляр класса ImageCache для использования в приложении.
    static let shared = ImageCache()
    /// Внутренний кэш для хранения изображений.
    private let cache = NSCache<NSString, UIImage>()
    /// Приватный инициализатор для предотвращения создания других экземпляров класса.
    private init() {}
    /// Возвращает изображение для заданного ключа.
    ///
    /// - Parameter key: Ключ, по которому хранится изображение.
    /// - Returns: Изображение, связанное с ключом, или nil, если изображение не найдено.
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    /// Сохраняет изображение в кэш с заданным ключом.
    ///
    /// - Parameters:
    ///   - image: Изображение для сохранения.
    ///   - key: Ключ, с которым будет связано изображение.
    func save(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    /// Удаляет изображение из кэша для заданного ключа.
    ///
    /// - Parameter key: Ключ, по которому будет удалено изображение.
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    /// Удаляет все изображения из кэша.
    func removeAllImages() {
        cache.removeAllObjects()
    }
}
