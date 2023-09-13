//
//  MetalCamera.swift
//  picaifinal
//
//  Created by AppleMini on 20/06/23.
//

import UIKit
import Metal
import MetalKit
import AVFoundation

extension ViewController: MTKViewDelegate,AVCaptureVideoDataOutputSampleBufferDelegate {
    

    
    func setupMetal(){
        //fetch the default gpu of the device (only one on iOS devices)
        metalDevice = MTLCreateSystemDefaultDevice()
        let metalFrame = UIView()
        metalFrame.translatesAutoresizingMaskIntoConstraints = false
        videoPreviewContainerView.addSubview(metalFrame)
        NSLayoutConstraint.activate([
            metalFrame.leadingAnchor.constraint(equalTo: videoPreviewContainerView.leadingAnchor),
            metalFrame.trailingAnchor.constraint(equalTo: videoPreviewContainerView.trailingAnchor),
            metalFrame.topAnchor.constraint(equalTo: cameraControls.bottomAnchor),
            metalFrame.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -16),
        ])
        view.layoutIfNeeded()
        firstMetalView = MTKView(frame: metalFrame.frame, device: metalDevice)
        //tell our MTKView which gpu to use
        //tell our MTKView to use explicit drawing meaning we have to call .draw() on it
        firstMetalView.isPaused = true
        firstMetalView.enableSetNeedsDisplay = false
        
        //create a command queue to be able to send down instructions to the GPU
        metalCommandQueue = metalDevice.makeCommandQueue()
        
        //conform to our MTKView's delegate
        firstMetalView.delegate = self
        //let it's drawable texture be writen to
        firstMetalView.framebufferOnly = false
        firstMetalView.contentMode = .scaleToFill
        videoPreviewContainerView.addSubview(firstMetalView)
        videoPreviewContainerView.sendSubviewToBack(firstMetalView)
        videoPreviewContainerView.bringSubviewToFront(sceneLabel)
        videoPreviewContainerView.bringSubviewToFront(captureButton)
        view.bringSubviewToFront(filteredImageView)
        
        let bounds = firstMetalView.drawableSize
        leftRect = CGRect(x: 0, y: 0, width: bounds.width/2, height: bounds.height)
        rightRect = CGRect(x: bounds.width/2, y: 0, width: bounds.width/2, height: bounds.height)
    }
    
    
    func setupCoreImage(){
        ciContext = CIContext(mtlDevice: metalDevice)
    }
    
    func setupAndStartCaptureSession() {
        //init session
        self.captureSession = AVCaptureSession()
        //start configuration
        self.captureSession.beginConfiguration()
        
        //session specific configuration
        if self.captureSession.canSetSessionPreset(.photo) {
            self.captureSession.sessionPreset = .hd1920x1080
        }
        self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
        //setup inputs
        self.setupInputs()
        
        //setup output
        self.setupOutput()
        
        //commit configuration
        self.captureSession.commitConfiguration()
        //start running it
        
    }
    
    func startRunningCamera() {
        startRunningCaptureSession()
    }
    
    func startRunningCaptureSession() {
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.startRunning()
        }
    }
    
    func stopRunnigCaptureSession(){
        DispatchQueue.global(qos: .background).async {
            self.captureSession?.stopRunning()
        }
    }
    
    func setupInputs() {
        
        if let device = primaryVideoDevice(forPosition: .back) {
            backCamera = device
            
        } else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }
        
        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }
        
        captureSession.addInput(backInput)
    }
    
    func primaryVideoDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        // -- Changes begun
        if #available(iOS 13.0, *) {
            
            
            let videoDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified).devices
            
            currentCamera = videoDevices.first(where: { $0.deviceType ==  .builtInWideAngleCamera})
            return currentCamera
            // Your iPhone has UltraWideCamera.
//            let deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
//            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
//            return discoverySession.devices.first
            
//            let hasUltraWideCamera: Bool = true // Set this variable to true if your device is one of the following - iPhone 11, iPhone 11 Pro, & iPhone 11 Pro Max
//
//            if hasUltraWideCamera {
//
//
//
//            }
            
        }
        // -- Changes end
        
        
        var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera] // builtInWideAngleCamera // builtInUltraWideCamera
        if #available(iOS 11.0, *) {
            deviceTypes.append(.builtInDualCamera)
        } else {
            deviceTypes.append(.builtInDuoCamera)
        }
        
        // prioritize duo camera systems before wide angle
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
        for device in discoverySession.devices {
            if #available(iOS 11.0, *) {
                if (device.deviceType == AVCaptureDevice.DeviceType.builtInDualCamera) {
                    return device
                }
            } else {
                if (device.deviceType == AVCaptureDevice.DeviceType.builtInDuoCamera) {
                    return device
                }
            }
        }
        
        return discoverySession.devices.first
        
    }
    
    
    
    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
        
    }
    
    func setupPreviewLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.frame
        firstMetalView.contentMode = .scaleToFill
//                view.layer.insertSublayer(videoPreviewLayer!, at: 0)
    }
    
    func setupCameras(){
        
        
        let videoDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified).devices
        
        wideCamera = videoDevices.first(where: { $0.deviceType ==  .builtInWideAngleCamera})
        ultraWideCamera = videoDevices.first(where: { $0.deviceType ==  .builtInUltraWideCamera})
        
//        var deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInUltraWideCamera]
//        var discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: .back)
////        captureSession.beginConfiguration()
//        ultraWideCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera], mediaType: .video, position: .unspecified).devices.first
//
//        deviceTypes = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
//        discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: .back)
////        captureSession.beginConfiguration()
//        wideCamera = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified).devices.first
        
    }

}
