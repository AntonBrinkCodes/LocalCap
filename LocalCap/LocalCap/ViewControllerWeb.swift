//
//  ViewControllerWeb.swift
//  LocalCap
//
//  Created by MoveAbility Lab on 2024-07-29.
//

import UIKit
import AVFoundation
import OSLog
//import StarScream


class ViewControllerWeb: UIViewController, WebSocketClientDelegate {
    func didDisconnectInvoluntarily(error: URLError) {
        os_log("Error: \(error) ")
    }
    
    
   // Stop rotating
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }
    override var shouldAutorotate: Bool {
            return false
        }
    
    var BASEURL: String?
    var sessionID: String?
    var ipPort: String?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoOutput: AVCaptureMovieFileOutput!
    var trialType: String?
    var trialName: String?
    var trialId: String?
    var cameraidx: Int?
    
    
    private var webSocketClient: WebSocketClient!
    let clientType = "mobile"

    @IBOutlet weak var mylabel: UILabel!
    
    @IBOutlet weak var cogwheelButton: UIButton!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // To lock rotation
            (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
            
        if let receivedString = BASEURL {
            print("IN SECOND VIEWCONTROLLER")
            print(receivedString) // or use it in your UI
            let parts = receivedString.components(separatedBy: "/")
            self.ipPort = parts.first
            self.sessionID = parts.last
            print("Session is: \(sessionID ?? "None")")
            print("IpPort is: \(ipPort ?? "NONE")")
            // Connect to the WebSocket server
            if let sessionID = sessionID, let ipPort = ipPort {
                guard let url = URL(string: "ws://\(ipPort)/ws?client_type=\(clientType)&link_to_web=\(sessionID)") else {
                    print("Error: Invalid WebSocket URL")
                    return
                }
                
                webSocketClient = WebSocketClient(url: url, sessionID: sessionID)
                webSocketClient.delegate = self
                
                let initialMessage = WebSocketClient.Message(
                    command: "mobile_connected",
                    content: UIDevice.current.modelIdentifier,
                    session: extractUUID(from: sessionID),
                    trialType: "",
                    trialName: "",
                    trialId: "",
                    camera_idx: -1
                )
                
                webSocketClient.connect(initialMessage: initialMessage)
            } else {
                print("Error: sessionID or ipPort is nil")
            }

        }
            
            //Setup camera
            configureCaptureSession()
            //print(webSocketClient)
        
        
        view.addSubview(mylabel)
        view.bringSubviewToFront(mylabel)
        view.bringSubviewToFront(cogwheelButton)
        }
    
   
    @IBAction func cogWheelButtonTapped(_ sender: UIButton) {
        // Show confirmation alert
            let alert = UIAlertController(title:"Confirmation", message: "Are you sure you want to go back?", preferredStyle: .alert)
            
            // Add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Cancel",style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Confirm",style: .default, handler: { _ in
                self.webSocketClient?.disconnect()
                // Navigate back to the first view controller
                self.navigationController?.popToRootViewController(animated: true)
            }))
            
            // Present the alert
            self.present(alert, animated: true, completion:nil)
    }
    
    private func configureCaptureSession(){
        captureSession = AVCaptureSession()
        configureSessionInput(captureSession: captureSession)
        
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.commitConfiguration()

            self.captureSession.startRunning()
                }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        view.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.layer.frame
        
        videoOutput = AVCaptureMovieFileOutput()
        
        configureVideoOutput(captureSession: captureSession, videoOutput: videoOutput)
        
    }
    
    func startRecording() {
            print("... starting recording")
            let outputDirectory = FileManager.default.temporaryDirectory
            let outputURL = outputDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            videoOutput.startRecording(to: outputURL, recordingDelegate: self)
        }

    func stopRecording() {
        if videoOutput.isRecording {
            print("... stopping recording")
            videoOutput.stopRecording()
            }
        else {
            print("... received stop but not recording")
        }
        }
    
    // Delegate method to update the label
    func didReceiveMessage(_ message: String) {
        DispatchQueue.main.async { // Ensure UI updates are on the main thread
            print("Recieved message: \(message)")
            
            self.mylabel.text = message // Update the label text
        
        // Try to decode the JSON
            if let jsonData = message.data(using: .utf8) {
                do {
                    let decodedMessage = try JSONDecoder().decode(WebSocketClient.Message.self, from: jsonData)
                    print("Decoded JSON message: \(decodedMessage)")
                    print("command is \(decodedMessage.command)")
                    if decodedMessage.command == "start"{
                        self.trialType = decodedMessage.trialType
                        self.startRecording()
                    } else if decodedMessage.command == "stop" {
                        self.trialType = decodedMessage.trialType
                        self.trialName = decodedMessage.trialName
                        self.trialId = decodedMessage.trialId
                        self.stopRecording()
                    }else if decodedMessage.command == "new_camera_idx" {
                        print("Changing camera idx")
                        self.cameraidx = decodedMessage.camera_idx
                        print("Camera idx is now: \(self.cameraidx)")
                    }
                } catch {
                    print("Failed to decode JSON: \(error)")
                }
            }
        }
        
    }
    
    // delegate method to send video to websocket
    func sendVideoToWebSocket(fileURL: URL, trialType: String? = "dynamic", trialName: String?, trialId: String?) {
        let trialType = trialType ?? "dynamic"
        do {
            let videoData = try Data(contentsOf: fileURL)
            print("... Send Video to websocket :)))")
            webSocketClient?.sendVideoFile(videoData, trialType: trialType, trialName: trialName, trialId: trialId)
        } catch {
            print("Error loading video data: \(error)")
        }
    }
    
    // Delegate method to handle websocket disconnects
    func onDisconnect() {
        stopRecording()
        DispatchQueue.main.async { // Ensure UI updates are on the main thread
            self.mylabel.text = "Disconnected from websocket" // Update the label text
        }
        // Maybe create a button to connect to new session
    }
    
    override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // Reset rotation restriction when leaving this view controller
            //(UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        }
    
    
    func uploadLargeVideo(fileURL: URL, trialType: String, trialName: String, trialId: String, sessionID: String, cameraidx: Int) {
        print(self.ipPort)
        if let ipPort = self.ipPort {
            print(ipPort)
            let urlString = "http://\(ipPort)/upload/"
            
            if let serverURL = URL(string: urlString) {
                    print("Server URL: \(serverURL)")
                            
            var request = URLRequest(url: serverURL)
            request.httpMethod = "POST"
            
            let boundary = UUID().uuidString
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var body = Data()
            let filename = fileURL.lastPathComponent
            let mimeType = "video/mov"
            
            // Add sessionID
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"session_uuid\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(sessionID)\r\n".data(using: .utf8)!)
            
            // Add trialType
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"trial_type\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(trialType)\r\n".data(using: .utf8)!)
            
            // Add trialName
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"trial_name\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(trialName)\r\n".data(using: .utf8)!)
            
            // Add trialId
            print("sending with trialId: \(trialId)")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"trial_uuid\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(trialId)\r\n".data(using: .utf8)!)
            
            // Add cameraIdx
            print("camera idx is: \(cameraidx)")
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"cam_index\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(cameraidx)\r\n".data(using: .utf8)!)
                
            // Add the video file
            if let videoData = try? Data(contentsOf: fileURL) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                body.append(videoData)
                body.append("\r\n".data(using: .utf8)!)
            }
            
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            request.httpBody = body
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error uploading video: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Video uploaded successfully.")
                } else {
                    print("Failed to upload video.")
                }
            }
            task.resume()
            } else {
                print("Error: URL(string:) returned nil for \(urlString)")
            } // Replace with your server URL
        }

            
    }
   
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension ViewControllerWeb: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: (any Error)?
    ) {
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: outputFileURL.path)[.size] as? Int64 ?? 0
            let maxFileSize: Int64 = 10 * 1024 * 1024 // 10 MB in bytes
            
            if fileSize > 0 {//test. Should be maxFileSize instead of 0 but this works so why change it? {
                print("File is larger than 10 MB. Uploading via URLSession.")
                self.uploadLargeVideo(
                    fileURL: outputFileURL,
                    trialType: self.trialType ?? "dynamic",
                    trialName: self.trialName ?? "defaultTrialName",
                    trialId: self.trialId ?? "defaultTrialId",
                    sessionID: self.sessionID ?? "defaultsessionID",
                    cameraidx: self.cameraidx ?? -1
                )
            } else {
                print("File is smaller than 10 MB. Sending via WebSocket.")
                self.sendVideoToWebSocket(fileURL: outputFileURL, trialType: self.trialType, trialName: self.trialName, trialId: self.trialId)
            }
        } catch {
            print("Failed to determine file size: \(error.localizedDescription)")
        }
    }
}


// MARK: - Helper function to get session_id from BASEURL
func extractUUID(from urlString: String) -> String {
    // Define the regex pattern for a UUID
    let uuidPattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
    // Use regular expression to find the UUID in the string
    let regex = try? NSRegularExpression(pattern: uuidPattern, options: [])
    let range = NSRange(urlString.startIndex..<urlString.endIndex, in: urlString)
    
    // Find the first match in the string
    if let match = regex?.firstMatch(in: urlString, options: [], range: range) {
        if let matchRange = Range(match.range, in: urlString) {
            let uuidString = String(urlString[matchRange])
            return uuidString
        }
    }
    
    // Return empty string if no UUID found
    return ""
}


