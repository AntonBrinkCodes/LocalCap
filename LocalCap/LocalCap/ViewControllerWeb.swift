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
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoOutput: AVCaptureMovieFileOutput!
    var trialType: String?
    
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
                // Connect to the WebSocket server
                if let url = URL(string: receivedString+"?client_type=\(clientType)") { // From scanned QR Code
                        webSocketClient = WebSocketClient(url: url)
                        webSocketClient.delegate = self
                        let initialMessage = WebSocketClient.Message(command: "mobile_connected", content: UIDevice.current.modelIdentifier,
                                                                     session_id: extractUUID(from: url.absoluteString), trialType: "")
                    webSocketClient.connect(initialMessage: initialMessage)
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
                        self.stopRecording()
                    }
                } catch {
                    print("Failed to decode JSON: \(error)")
                }
            }
        }
        
    }
    
    // delegate method to send video to websocket
    func sendVideoToWebSocket(fileURL: URL, trialType: String? = "dynamic") {
        let trialType = trialType ?? "dynamic"
        do {
            let videoData = try Data(contentsOf: fileURL)
            print("... Send Video to websocket :)))")
            webSocketClient?.sendVideoFile(videoData, trialType: trialType)
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
   
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension ViewControllerWeb: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        self.sendVideoToWebSocket(fileURL: outputFileURL, trialType: self.trialType)
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
