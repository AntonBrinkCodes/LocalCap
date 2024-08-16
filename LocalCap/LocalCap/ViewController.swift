import UIKit
import AVFoundation
import OSLog



// implements AVCaptureMetadataOutputObjectsDelegate 
class ViewController: UIViewController {

    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var QROutput: AVCaptureMetadataOutput!
    var BASEURL: String!

    var button: UIButton!
    
   
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        print("Supported Interface Orientations called")
        return .portrait
    }

    override var shouldAutorotate: Bool {
        print("Should Autorotate called")
        return false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("Running viewWillAppear")
        super.viewWillAppear(animated)
        // To lock rotation
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        let deviceModel = UIDevice.current.modelIdentifier
        print("Device Model: \(deviceModel)")
        enableQRCodeScanning()
    }
    override func viewDidLoad() {
        print("running viewDidLoad")
        super.viewDidLoad()
        configureCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = view.layer.frame
        
        // Simulating a delay to re-enable QR code scanning after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if let previousVC = self.presentingViewController as? ViewController {
                print("if let self stuff")
                previousVC.enableQRCodeScanning()
            }
        }
    }
    
    private func configureCaptureSession() {
        captureSession = AVCaptureSession()
        // Configure input
        configureSessionInput(captureSession: captureSession)
        
        // Set QR code output
        print("setting QR output?")
        QROutput = AVCaptureMetadataOutput()
        QROutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(QROutput)
        print("setting metadataobjecttypes to QR")
        print("Available MetaDataObject Types: \(QROutput.availableMetadataObjectTypes)")
        QROutput.metadataObjectTypes = [.qr]
        print("commiting to configuration")
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
        //print(captureDeviceInput.device.activeFormat)
    }
    
    // Method to re-enable QR code scanning
        func enableQRCodeScanning() {
            print("trying to re-enable QR output")
            if !captureSession.outputs.contains(QROutput) {
                print("... Adding QR output")
                captureSession.addOutput(QROutput)
                QROutput.metadataObjectTypes = [.qr]
            }
        }
    
 
    
    
    
    /// MARK: - Constants
    private enum Constants {
        static let alerTitle = "Scanning is not supported"
        static let alertMessage = "Your device does not support scanning a code from an item. Please use a device with a camera"
        static let alertButtonTitle = "OK"
    }
    
    /// MARK:  - showalert
    func showAlert(){
        let alert = UIAlertController(title: Constants.alerTitle,
                                      message: Constants.alertMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Constants.alerTitle,
                        style: .default))
        present(alert, animated: true)
    }
    
/// MARK: - Send BASEURL to ViewControllerWeb which has Websocket
///     var stringToPass: String = "Hello, Second ViewController!"

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSecondViewController" {
            print("we are in prepare")
            if let destinationVC = segue.destination as? ViewControllerWeb {
                destinationVC.BASEURL = BASEURL
            }
        }
    }
    

    
    deinit{
        print("running deinit")
        captureSession.stopRunning()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Print a message when the screen rotates
        coordinator.animate(alongsideTransition: { _ in
            print("Screen rotated to size: \(size)")
        }, completion: { _ in
            print("Rotation complete")
        })
    }

}



/// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ViewController: AVCaptureMetadataOutputObjectsDelegate{
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           metadataObject.type == .qr {
            if let stringValue = metadataObject.stringValue {
                captureSession.removeOutput(QROutput)
                print("WHAT IS BASEURL:")
                print(stringValue) // debug
                // Send request to back-end fastAPI.
                //sendRequest(to: url)
                BASEURL = stringValue
                // Additional processing with stringValue can be done here
                // Send string to ViewControllerWeb
                prepare(for: UIStoryboardSegue(identifier: "showSecondViewController", source: self, destination: ViewControllerWeb.init()), sender: self)
                performSegue(withIdentifier: "showSecondViewController", sender: self)
            }
        }
    }
    
    // First request with back-end
    func sendRequest(to url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                return
            }
            // Handle the response data
            print("Response: \(String(describing: String(data: data, encoding: .utf8)))")
            
        }
        
        task.resume()
    }
    
    func sendTestRequest(to url: URL, completion: @escaping (String) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "No data")")
                completion("") // Return an empty string or handle the error as needed
                return
            }
            
            let serverResponse = String(data: data, encoding: .utf8) ?? ""
            print(serverResponse)
            completion(serverResponse)
        }
        
        task.resume()
    }
    
  
}

extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }
}
