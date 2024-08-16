//
//  Websocket.swift
//  LocalCap
//
//  Created by MoveAbility Lab on 2024-07-30.
//

import Foundation

class WebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    weak var delegate: WebSocketClientDelegate?
    
    init(url: URL) {
        self.url = url
    }
    
    // Connect to the WebSocket server
    func connect(initialMessage: Message? = nil) {
        let urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Send a message to the server upon connection
        if let message = initialMessage {
            sendMessage(message)
        }
        // Start receiving messages
        receiveMessages()
        
        
        
        

    }
    
    // Example of a custom struct to represent JSON data
    struct Message: Codable {
        let command: String
        let content: String
        let session_id: String
        let trialType: String
    }

    func sendMessage(_ message: Message) {
        do {
            // Encode the message struct to JSON data
            let jsonData = try JSONEncoder().encode(message)
            
            // Convert JSON data to a string
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Create a WebSocket message
                let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
                
                // Send the WebSocket message
                print("sending message: \(message) ...")
                webSocketTask?.send(wsMessage) { error in
                    if let error = error {
                        print("Error sending message: \(error)")
                    }
                }
            }
        } catch {
            print("Error encoding message to JSON: \(error)")
        }
    }
    
    // Send binary data to the WebSocket server
    func sendMessage(_ data: Data) {
        let message = URLSessionWebSocketTask.Message.data(data)
        print("sending data...")
        webSocketTask?.send(message) { error in
            if let error = error {
                print("Error sending data: \(error)")
            }
        }
    }
    
    
    // Send video as json with descriptive information
    func sendVideoFile(_ data: Data, trialType: String) {
        print("... sending video file with json")
            do {
                // Load the video file
                
                // Encode the video data as Base64
                let base64String = data.base64EncodedString()
                
                // Create JSON metadata
                let metadata: [String: Any] = [
                    "type": "video",
                    "name": trialType,
                    "size": base64String.count, // size in bytes
                    "description": "This is an example video file."
                ]
                
                // Combine metadata and encoded video
                let message: [String: Any] = [
                    "command": "save_video",
                    "metadata": metadata,
                    "videoData": base64String
                ]
                
                // Convert the message to JSON data
                let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
                let jsonString = String(data: jsonData, encoding: .utf8)
                print(".... Sending Video!!!!!")
                // Create WebSocket message
                if let jsonString = jsonString {
                    let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
                    webSocketTask?.send(wsMessage) { error in
                        if let error = error {
                            print("Error sending message: \(error)")
                        }
                    }
                }
            } catch {
                print("Error reading video file: \(error)")
            }
        }
    
    
    // Receive messages from the WebSocket server
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("Error receiving message: \(error)")
                self?.handleError(error)
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text in websocket: \(text)")
                    self?.delegate?.didReceiveMessage(text)
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    fatalError()
                }
                // Continue receiving messages
                self?.receiveMessages()
            }
        }
    }
    
    private func handleError(_ error: Error){
        if let urlError = error as? URLError, urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                    // Notify about involuntary disconnection
                    self.delegate?.didDisconnectInvoluntarily(error: urlError)
                } else {
                    // Other errors can be handled here if needed
                }
    }
    
    
    // Disconnect from the WebSocket server
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        self.delegate?.onDisconnect()
    }
}

protocol WebSocketClientDelegate: AnyObject {
    func didReceiveMessage(_ message: String)
    func onDisconnect()
    func didDisconnectInvoluntarily(error: URLError)
}
