//
//  Ext+UIImage.swift
//  SimpleChat
//
//  Created by sofiigorevna on 23.07.2025.
//

import UIKit

extension UIImage {
    /**
     Удобный инициализатор для создания UIImage с однородным цветом.
     
     - Parameter color: Цвет, которым будет заполнено изображение.
     
     - Returns: UIImage, заполненное указанным цветом.
     */
    convenience init(color: UIColor) {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        self.init(cgImage: img.cgImage!)
    }
    /**
     Асинхронно загружает изображение по указанному URL-адресу.
     
     - Parameters:
     - urlString: Строка URL-адреса, по которой будет загружено изображение.
     - completion: Замыкание, которое будет вызвано после завершения операции загрузки изображения. Замыкание принимает единственный параметр типа UIImage?, который представляет загруженное изображение. Если изображение не удалось загрузить, в замыкание передается nil.
     
     - Note: Если изображение не удалось загрузить, в качестве плейсхолдера будет передано изображение с именем "not_photo".
     */
    static func loadImage(from urlString: String, completion: @escaping (UIImage?) -> ()) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        if let cachedImage = ImageCache.shared.image(forKey: urlString) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
        } else {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Ошибка загрузки изображения: \(error)")
                    DispatchQueue.main.async {
                        completion(Images.emptyImage.image)
                    }
                    return
                }
                
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        ImageCache.shared.save(image, forKey: urlString)
                        completion(image)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(Images.emptyImage.image)
                    }
                }
            }.resume()
        }
    }
    
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        
        draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
