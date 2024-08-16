//
//  cameraConfig.swift
//  LocalCap
//
//  Created by MoveAbility Lab on 2024-07-30.
//
import OSLog
import AVFoundation


/**
 Configures the given capture session with specified frame rate and resolution.

 - Parameters:
    - captureSession: The AVCaptureSession instance to be configured.
    - targetFrameRate: The desired frame rate for the capture session (default is 60).
    - targetWidth: The desired width for the capture session (default is 1280).
    - targetHeight: The desired height for the capture session (default is 720).

 This function sets the active format of the back camera to a format that supports the desired
 frame rate and resolution. It also configures auto-focus settings and ensures the capture
 session is prepared for video capture.
 */
public func configureSessionInput(captureSession: AVCaptureSession, targetFrameRate: Int = 60, targetWidth: Int = 1280, targetHeight: Int = 720) {
    captureSession.beginConfiguration()
    
    // Get the default back camera
    guard let currentDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
        print("No back camera available.")
        return
    }
    
    // Create an input for the capture session
    guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
        print("Unable to create AVCaptureDeviceInput.")
        return
    }
    
    print(captureDeviceInput.device.activeFormat)
    
    // Configure smooth auto-focus
    if currentDevice.isSmoothAutoFocusSupported {
        do {
            try currentDevice.lockForConfiguration()
            currentDevice.isSmoothAutoFocusEnabled = false
            currentDevice.unlockForConfiguration()
        } catch {
            print("Error changing device smooth autofocus: \(error)")
        }
    }

    // Find a suitable format that matches the desired width, height, and frame rate
    var formatToSet: AVCaptureDevice.Format = currentDevice.activeFormat
    for format in currentDevice.formats.reversed() {
        let ranges = format.videoSupportedFrameRateRanges
        guard let frameRates = ranges.first else { continue }
        
        if frameRates.maxFrameRate == Double(targetFrameRate),
           frameRates.minFrameRate == Double(1),
           format.formatDescription.dimensions.width == targetWidth,
           format.formatDescription.dimensions.height == targetHeight {
            print("Selected format: \(format)")
            formatToSet = format
            break
        }
    }
    
    // Add the input to the capture session
    captureSession.addInput(captureDeviceInput)
    
    // Change to the desired format and frame rate
    do {
        try captureDeviceInput.device.lockForConfiguration()
        captureDeviceInput.device.activeFormat = formatToSet
        
        let timescale = CMTimeScale(targetFrameRate)
        if currentDevice.activeFormat.videoSupportedFrameRateRanges[0].maxFrameRate >= Double(targetFrameRate) {
            currentDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: timescale)
            currentDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: timescale)
            print("Configured frame rate: \(timescale)")
        } else {
            print("Selected format does not support the desired frame rate of \(targetFrameRate) FPS")
        }
        currentDevice.unlockForConfiguration()
    } catch {
        print("Error setting frame rate: \(error)")
    }
}

/// Configures the video output for a given capture session.
///
/// This function attempts to add the specified `AVCaptureMovieFileOutput` to the provided
/// `AVCaptureSession`. If the output can be added to the session, it will be added; otherwise,
/// an error message will be printed.
///
/// - Parameters:
///   - captureSession: The `AVCaptureSession` instance to which the video output will be added.
///   - videoOutput: The `AVCaptureMovieFileOutput` instance that will be configured for video capture.
///
/// - Note:
/// This function does not configure the video input itself. It assumes that the video input
/// has already been set up in the capture session.
public func configureVideoOutput(captureSession: AVCaptureSession, videoOutput: AVCaptureMovieFileOutput){
    if (captureSession.canAddOutput(videoOutput)) {
                captureSession.addOutput(videoOutput)
            } else {
                print("ERROR ADDING VIDEO OUTPUT")
                return
            }
}

//public func configureQROutput(captureSession: AVCaptureSession, qrOutput: AVCaptureMetadataOutput){
    
//}
