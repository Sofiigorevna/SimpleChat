//
//  WebSocketManager.swift
//  SimpleChat
//
//  Created by sofiigorevna on 09.07.2025.
//

import Foundation
import Starscream

enum WebSocketContent {
    case text(String)
    case image([Data]?)
    case imageWithText(text: String, image: [Data]?)
    case document(data: Data, fileName: String, mimeType: String)
}

protocol WebSocketManagerDelegate: AnyObject {
    func didReceiveContent(_ message: WebSocketContent)
    func didEncounterError(_ error: String)
}

final class WebSocketManager {
    private var socket: WebSocket?
    private let serverURL = URL(string: "wss://echo.websocket.events")!
    weak var delegate: WebSocketManagerDelegate?
    
    init() {
        setupSocket()
    }
    
    private func setupSocket() {
        var request = URLRequest(url: serverURL)
        request.timeoutInterval = 10
        socket = WebSocket(request: request)
        socket?.delegate = self
    }
    
    func connect() {
        socket?.connect()
    }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    func sendMessage(_ text: String) {
        socket?.write(string: text)
    }
    
    func sendImageMessage(_ data: Data) {
        socket?.write(data: data)
    }
    
    func sendDocumentMessage(_ data: Data) {
        socket?.write(data: data)
    }
    
    func sendTextAndImage(text: String, imageData: [Data]) {
        let base64Strings = imageData.map { $0.base64EncodedString() }
        var messageDict: [String: Any] = [:]
        
        if !imageData.isEmpty && !text.isEmpty {
               // Случай: текст + изображения
               messageDict = [
                   "type": "image+text",
                   "text": text,
                   "images": base64Strings
               ]
           } else if !imageData.isEmpty {
               // Случай: только изображения
               messageDict = [
                   "type": "image",
                   "images": base64Strings
               ]
           } else {
               // Случай: только текст
               messageDict = [
                "type": "text",
                "text": text
               ]
           }
        if let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            socket?.write(string: jsonString)
        }
    }
    
    func send(content: WebSocketContent) {
        switch content {
        case .text(let text):
            sendMessage(text)
            
        case .image(let imagesData):
            let imageData = imagesData ?? []
            sendTextAndImage(text: "", imageData: imageData)
            
        case .imageWithText(let text, let imagesData):
            let imageData = imagesData ?? []
            sendTextAndImage(text: text, imageData: imageData)
            
        case .document(let data, let fileName, let mimeType):
            let base64 = data.base64EncodedString()
            
            let messageDict: [String: Any] = [
                "type": "document",
                "fileName": fileName,
                "mimeType": mimeType,
                "data": base64
            ]
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: messageDict),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                socket?.write(string: jsonString)
            }
        }
    }
}

extension WebSocketManager: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
            case .connected(let headers):
                print("Connected: \(headers)\n\n")
            case .disconnected(let reason, let code):
                delegate?.didEncounterError("Disconnected: \(reason) (code: \(code))\n\n")
               
            case .text(let message):
                if let data = message.data(using: .utf8),
                   let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let type = dict["type"] as? String {

                    switch type {
                        case "text":
                            if let text = dict["text"] as? String {
                                delegate?.didReceiveContent(.text(text))
                            } else {
                                print("\(#file.components(separatedBy: "/").last ?? "") \(#function) \(#line)\\n")
                            }
                            
                        case "image+text":
                            guard let base64Strings = dict["images"] as? [String],
                                  let text = dict["text"] as? String else {
                                print("Invalid image+text format")
                                break
                            }
                            var imagesData = [Data]()
                            // Обрабатываем все полученные изображения
                            for base64String in base64Strings {
                                let cleanBase64 = base64String
                                    .replacingOccurrences(of: "^data:image/\\w+;base64,",
                                                        with: "",
                                                        options: .regularExpression)
                            
                                if let imageData = Data(base64Encoded: cleanBase64) {
                                            imagesData.append(imageData)
                                    delegate?.didReceiveContent(.imageWithText(text: text, image: imagesData))

                                        } else {
                                            print("Failed to decode base64 image")
                                        }
                            }

                        case "image":
                            guard let base64Strings = dict["images"] as? [String] else {
                                print("Invalid image format")
                                break
                            }
                            
                            var imagesData = [Data]()

                            for base64String in base64Strings {
                                let cleanBase64 = base64String
                                    .replacingOccurrences(of: "^data:image/\\w+;base64,",
                                                        with: "",
                                                        options: .regularExpression)
                                if let imageData = Data(base64Encoded: cleanBase64) {
                                            imagesData.append(imageData)
                                    delegate?.didReceiveContent(.image(imagesData))

                                        } else {
                                            print("Failed to decode base64 image")
                                        }
                            }
                            
                        case "document":
                            guard let fileName = dict["fileName"] as? String,
                                  let mimeType = dict["mimeType"] as? String,
                                  let base64String = dict["data"] as? String else {
                                print("Invalid document format")
                                break
                            }
                            let cleanBase64 = base64String
                                .replacingOccurrences(of: "^data:.*;base64,", with: "", options: .regularExpression)
                            if let documentData = Data(base64Encoded: cleanBase64) {
                                delegate?.didReceiveContent(.document(data: documentData, fileName: fileName, mimeType: mimeType))
                            } else {
                                print("Failed to decode base64 document data")
                            }

                        default:
                            print("\(#file.components(separatedBy: "/").last ?? "") \(#function) \(#line)\\n")
                            break
                    }
                } else {
                    delegate?.didReceiveContent(.text(message))
                }
            case .error(let error):
                print("\(#file.components(separatedBy: "/").last ?? "") \(#function) \(#line)\n error\n")
                delegate?.didEncounterError(error?.localizedDescription ?? "Unknown error")
            default:
                print("\(#file.components(separatedBy: "/").last ?? "") \(#function) \(#line)\n default\n")
                break
        }
    }
}
