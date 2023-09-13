//
//  CameraUtils.swift
//  picaifinal
//
//  Created by AppleMini on 20/06/23.
//

import UIKit
import MetalKit
import AVFoundation
import CoreMedia
import Photos

extension ViewController {
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle drawable size changes if needed
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let currentCIImage = ciImage else {
            return
        }
        guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
            return
        }
        
        guard let clearImage  = resizeCIImage(to: firstMetalView.drawableSize, ciImage: currentCIImage) else{
            return
        }
        
        
        
        let image1 = clearImage.cropped(to: leftRect)
        let image2 = clearImage.cropped(to: rightRect)
        
        let filteredLeftImage: CIImage
        let filteredRightImage: CIImage
        
        if let leftFilter = leftFilters {
            let leftFilt = CIFilter(name: leftFilter[leftFilterIndex].name, parameters: leftFilter[leftFilterIndex].parameters)
            let inputKeys = leftFilt?.inputKeys
            if let inputKeys = inputKeys{
                
                if inputKeys.contains(kCIInputIntensityKey) {
                    if isLeftExpanded{
                        intensitySlider.isHidden = false
                        if !intensitySliderValueSet {
                            intensitySlider.value = leftFilt?.value(forKey: kCIInputIntensityKey) as! Float
                            intensitySliderValueSet = true
                        }
                        self.view.bringSubviewToFront(intensitySlider)
                        leftFilt?.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
                    }
                    else{
                        intensitySlider.isHidden = true
                    }
                    
                } else {
                    intensitySlider.isHidden = true
                }
            }
            else{
                intensitySlider.isHidden = true
            }
            
            if !isLeftExpanded{
                intensitySlider.isHidden = true
            }
            
            leftFilt?.setValue(image1, forKey: kCIInputImageKey)
            filteredLeftImage = leftFilt?.outputImage ?? image1
        }
        else{
            filteredLeftImage = image1
        }
        
        if let rightFilter = rightFilters{
            let rightFilt = CIFilter(name: rightFilter[rightFilterIndex].name, parameters: rightFilter[rightFilterIndex].parameters)
            let inputKeys = rightFilt?.inputKeys
            if let inputKeys = inputKeys{
                if inputKeys.contains(kCIInputIntensityKey) {
                    if isRightExpanded{
                        intensitySlider.isHidden = false
                        if !intensitySliderValueSet {
                            intensitySlider.value = rightFilt?.value(forKey: kCIInputIntensityKey) as! Float
                            intensitySliderValueSet = true
                        }
                        self.view.bringSubviewToFront(intensitySlider)
                        rightFilt?.setValue(intensitySlider.value, forKey: kCIInputIntensityKey)
                    }
                    else{
                        intensitySlider.isHidden = true
                    }
                    
                } else {
                    intensitySlider.isHidden = true
                }
            }
            else{
                intensitySlider.isHidden = true
            }
            
            if !isRightExpanded
            {
                intensitySlider.isHidden = true
            }
            rightFilt?.setValue(image2, forKey: kCIInputImageKey)
            filteredRightImage = rightFilt?.outputImage ?? image2
        }
        else{
            filteredRightImage = image2
        }
        
        let sourceOverCompositing = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositing.setValue(filteredLeftImage, forKey: kCIInputBackgroundImageKey)
        sourceOverCompositing.setValue(filteredRightImage, forKey: kCIInputImageKey)
        let composedImage = sourceOverCompositing.outputImage!
        filteredCIImage = composedImage
        self.ciContext.render(composedImage,
                              to: drawable.texture,
                              commandBuffer: commandBuffer,
                              bounds: CGRect(origin: .zero, size: self.firstMetalView.drawableSize),
                              colorSpace: CGColorSpaceCreateDeviceRGB())
        
        
        //register where to draw the instructions in the command buffer once it executes
        commandBuffer.present(drawable)
        //commit the command to the queue so it executes
        commandBuffer.commit()
    }
    
    
    @objc func zoomChanged(_ sender: UISegmentedControl){
        print("changing zoom to \(sender.selectedSegmentIndex)")
        let selectedSegmentIndex = sender.selectedSegmentIndex
        var zoomFactor: CGFloat = 1.0
        
        switch selectedSegmentIndex {
        case 0:
            zoomFactor = 1.0
        case 1:
            zoomFactor = 2.0
        case 2:
            zoomFactor = 4.0
        default:
            break
        }
        
        setCameraZoom(zoomFactor)
        setupZoomGesture()
    }
    
    
//    func setupCaptureSession() {
//            captureSession = AVCaptureSession()
//
//            // Find the available video devices
//            let videoDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera], mediaType: .video, position: .unspecified).devices
//
//            // Set the initial camera to the wide-angle camera
//            currentCamera = videoDevices.first(where: { $0.deviceType == .builtInWideAngleCamera })
//
//            // Create an input with the initial camera
//            if let camera = currentCamera {
//                do {
//                    let cameraInput = try AVCaptureDeviceInput(device: camera)
//                    if let captureSession = captureSession, captureSession.canAddInput(cameraInput) {
//                        captureSession.addInput(cameraInput)
//                    }
//                } catch {
//                    print("Failed to create input device: \(error)")
//                }
//            }
//
//            // Configure and add the photo output
//            capturePhotoOutput = AVCapturePhotoOutput()
//            if let capturePhotoOutput = capturePhotoOutput {
//                if let captureSession = captureSession, captureSession.canAddOutput(capturePhotoOutput) {
//                    captureSession.addOutput(capturePhotoOutput)
//                }
//            }
//        }
//
//
//
    private func setupZoomGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
    }

    @objc private func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard var camera = currentCamera else { return }

        func updateZoomFactor(_ factor: CGFloat) {
            do {
                try camera.lockForConfiguration()
                defer { camera.unlockForConfiguration() }

                camera.videoZoomFactor = factor

                // Update the current zoom factor
                currentZoomFactor = factor
            } catch {
                print("Failed to update zoom factor: \(error)")
            }
        }

        switch gesture.state {
        case .changed:
            let newZoomFactor = currentZoomFactor * gesture.scale
            let clampedZoomFactor = max(1, min(newZoomFactor, camera.maxAvailableVideoZoomFactor/2))
            
            print("clampedZoomFactor: ", clampedZoomFactor)
            
            if clampedZoomFactor <= 1.0
            {
//                camera = ultraWideCamera!

                
            // Create a new input with the ultra-wide camera
                do
                {
                    let ultraWideCameraInput = try AVCaptureDeviceInput(device: ultraWideCamera!)
                    if captureSession.canAddInput(ultraWideCameraInput) {
                        captureSession.addInput(ultraWideCameraInput)
                    }
                    
                    // Commit the configuration changes
                    captureSession.commitConfiguration()
                                            
                                            // Set the current camera as the ultra-wide camera
                    camera = ultraWideCamera!
                    videoOutput.connections.first?.videoOrientation = .portrait
                    

                }
                catch
                {
                    print("ERROR!!")
                }
                
            
            // Add the ultra-wide camera input to the capture session
            
                
            }
            else
            {
//                let deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
//                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: .back)
//
//                camera = discoverySession.devices.first!
//                                    captureSession.commitConfiguration()
//                    videoOutput.connections.first?.videoOrientation = .portrait
                
                
            // Create a new input with the ultra-wide camera
                do
                {
                    let WideCameraInput = try AVCaptureDeviceInput(device: wideCamera!)
                    if captureSession.canAddInput(WideCameraInput) {
                        captureSession.addInput(WideCameraInput)
                    }
                    
                    // Commit the configuration changes
                    captureSession.commitConfiguration()
                                            
                                            // Set the current camera as the ultra-wide camera
                        camera = wideCamera!
                    videoOutput.connections.first?.videoOrientation = .portrait

                }
                catch
                {
                }
      


            }
            updateZoomFactor(clampedZoomFactor)
        case .ended:
            gesture.scale = 1.0
        default:
            break
        }
    }
        
    
    
    func setCameraZoom(_ zoomFactor: CGFloat) {
        guard let device = backCamera else {
            return
        }

        do {
            try device.lockForConfiguration()

            let maxZoomFactor = device.maxAvailableVideoZoomFactor
            let clampedZoomFactor = max(1.0, min(maxZoomFactor, zoomFactor))

            // Calculate the relative zoom factor
            let relativeZoomFactor = clampedZoomFactor
            // Smoothly ramp to the desired zoom factor
            device.ramp(toVideoZoomFactor: relativeZoomFactor, withRate: 2.0)
            device.unlockForConfiguration()

        } catch {
            // Handle zoom configuration error
            return
        }
    }
    
    
    @objc func switchCamera(_ sender: UIButton){
        //videoCapture.toggleCamera()
        switchCamera.isUserInteractionEnabled = false
        
        //reconfigure the input
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            
            backCameraOn = true
        }
        
        //deal with the connection again for portrait mode
        videoOutput.connections.first?.videoOrientation = .portrait
        
        //mirror video if front camera
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        //commit config
        captureSession.commitConfiguration()
        
        if backCameraOn{
            zoomChanged(zoomControl)
        }
        
        //acitvate the camera button again
        switchCamera.isUserInteractionEnabled = true
    }
    
    
    
    @objc func captureButtonClicked(_ sender: UIButton){
        takePicture = true
        isFrameCaptured = false
        feedbackGenerator?.selectionChanged()
        audioPlayer?.play()

        print("capturing photo")
    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //try and get a CVImageBuffer out of the sample buffer
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        self.storedCVBuffer = cvBuffer
        frameCounter += 1
        if (frameCounter % 150 == 0 || frameCounter == 30) && isAutomaticDetect{
            predictUsingVision(pixelBuffer: cvBuffer)
        }
        if !isAutomaticDetect{
            
        }
        
        
        
        //get a CIImage out of the CVImageBuffer
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        self.ciImage = ciImage
        
        //get UIImage out of CIImage
        //let uiImage = UIImage(ciImage: filteredCIImage)
        DispatchQueue.main.async {
            
            self.firstMetalView.draw()
        }
        
        if !takePicture {
            return //we have nothing to do with the image buffer
        }
        
        
        
        DispatchQueue.main.async { [self] in
            guard !isFrameCaptured else{
                return
            }
            guard let filteredCIImage = filteredCIImage else{
                return
            }
            filteredImageView.isHidden = false
            let context = self.ciContext
            guard let cgImage = context?.createCGImage(filteredCIImage, from: filteredCIImage.extent) else { return }
            let uiImage = UIImage(cgImage: cgImage)
            filteredImageView.image = uiImage
            filteredUIImage = uiImage
            guard let originalCgImage = context?.createCGImage(ciImage, from: ciImage.extent) else {return}
            let originalUIImage = UIImage(cgImage: originalCgImage)
            self.originalUIImage = originalUIImage
            saveImage(image: uiImage, albumName: albumName)
            isFrameCaptured = true
            self.takePicture = false
        }
        
        
    }
    
    func requestPhotoLibraryAccess() -> Bool{
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            // The user has previously granted access to the photo library.
            return true
            
        case .denied, .restricted:
            // The user has previously denied access or access is restricted due to parental controls.
            return false
            
        case .notDetermined:
            // The user has not yet been asked for photo library access.
            var flag = false
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    // The user has granted access to the photo library. Call your method to save the photo here.
                    DispatchQueue.main.async {
                        print("Authorized")
                        flag = true
                    }
                    
                } else {
                    print("Not authorise")
                }
            }
            if flag{
                return true
            }
            return false
        @unknown default:
            return false
        }
    }
    
    func saveImage(image: UIImage, albumName: String) {
        // Check if the album exists
        if requestPhotoLibraryAccess(){
            var album: PHAssetCollection?
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "title = %@", albumName)
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
            if collections.firstObject != nil {
                // Album exists
                album = collections.firstObject
            } else {
                // Album doesn't exist - create it
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                }, completionHandler: { success, error in
                    if success {
                        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
                        album = collections.firstObject
                    } else if let error = error {
                        // Handle the error
                        print("Error creating album: \(error)")
                    }
                })
            }
            
            // Save the image to the album
            PHPhotoLibrary.shared().performChanges({
                let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album!)
                albumChangeRequest?.addAssets([assetPlaceholder!] as NSArray)
            }, completionHandler: { success, error in
                if !success, let error = error {
                    // Handle the error
                    print("Error saving photo: \(error)")
                }
            })
        }
        
    }
    
    func resizeCIImage(to screenSize: CGSize, ciImage: CIImage) -> CIImage? {
        let ciContext = CIContext()
        let scaleX = screenSize.width / ciImage.extent.width
        let scaleY = screenSize.height / ciImage.extent.height
        let scaleTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        // Apply the scale transform to resize the CIImage
        let resizedCIImage = ciImage.transformed(by: scaleTransform)
        
        // Render the resized CIImage to a CGImage
        guard let cgImage = ciContext.createCGImage(resizedCIImage, from: resizedCIImage.extent) else {
            return nil
        }
        
        // Create a new CIImage from the resized CGImage
        return CIImage(cgImage: cgImage)
    }

}
