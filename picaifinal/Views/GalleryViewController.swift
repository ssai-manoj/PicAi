//
//  ImageViewController.swift
//  picaifinal
//
//  Created by AppleMini on 08/06/23.
//

import UIKit
import Photos
import Vision
import MetalKit

protocol GalleryViewControllerDelegate {
    func startRunningCamera()
}

class GalleryViewController: UIViewController {
    var delegate: GalleryViewControllerDelegate?
    var image: UIImage!
    var imageView: UIView!
    lazy var objectDectectionModel = { return try? YOLOv3() }()
    var boxesView: DrawingBoundingBoxView = DrawingBoundingBoxView()
    var visionModel: VNCoreMLModel?
    var request: VNCoreMLRequest?
    let semaphore = DispatchSemaphore(value: 1)
    var predictions: [VNRecognizedObjectObservation] = []
    var metalDevice : MTLDevice!
    var metalCommandQueue : MTLCommandQueue!
    var firstMetalView: MTKView!
    var leftRect: CGRect!
    var rightRect: CGRect!
    var leftView = UIView()
    var rightView = UIView()
    var leftFilters: [Filter]?
    var rightFilters: [Filter]?
    var globalScenesArray: [Scene] = []
    var rightViewWidth: NSLayoutConstraint!
    var leftViewWidth: NSLayoutConstraint!
    var leftFilterIndex = 0
    var rightFilterIndex = 0
    let albumName = "PicAi"
    var intensitySlider: UISlider = UISlider()
    //MARK: UI variables
    var isLeftExpanded = false
    var isRightExpanded = false
    var intensitySliderValueSet = false
    var storedScene: String?
    var feedbackGenerator: UISelectionFeedbackGenerator?
    var sceneLabel: UILabel = UILabel()
    var ciImage: CIImage?
    var ciContext: CIContext!
    var filteredCIImage: CIImage?
    let navBar = UIView()
    let saveButton = UIButton(type: .system)
    let backButton = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        boxesView.delegate = self
        setupUI()
        setupMetal()
        // Do any additional setup after loading the view.
        loadModel()
        imageLoaded()
        loadFilterData()
        setupCoreImage()
    }
    
    func setupUI() {
        view.isUserInteractionEnabled = true
        view.backgroundColor = .black
        imageView = UIView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        intensitySlider.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        saveButton.tintColor = .white
        saveButton.setTitle("Save", for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
               
        backButton.tintColor = .white
        backButton.setTitle("Back", for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        
        
        
        // Create a custom navigation bar
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        navBar.addSubview(saveButton)
        navBar.addSubview(backButton)
        leftView.translatesAutoresizingMaskIntoConstraints = false
        rightView.translatesAutoresizingMaskIntoConstraints = false
        sceneLabel.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(leftView)
        imageView.addSubview(rightView)
        imageView.addSubview(sceneLabel)
        imageView.addSubview(intensitySlider)
        leftView.backgroundColor = .clear
        rightView.backgroundColor = .clear
        sceneLabel.font = UIFont.systemFont(ofSize: 36, weight: .black)
        navBar.backgroundColor = .white.withAlphaComponent(0.5)
        NSLayoutConstraint.activate([
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.06),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            sceneLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            sceneLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            saveButton.trailingAnchor.constraint(equalTo: navBar.trailingAnchor, constant: -16),
            saveButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            
            backButton.leadingAnchor.constraint(equalTo: navBar.leadingAnchor, constant: 16),
            backButton.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
            
            intensitySlider.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 16),
            intensitySlider.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -16),
            intensitySlider.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -16)
            
        ])
        
        
        leftViewWidth = leftView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        rightViewWidth = rightView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        
        NSLayoutConstraint.activate([
            leftView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftView.topAnchor.constraint(equalTo: imageView.topAnchor),
            leftView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leftViewWidth,
            
            rightView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightView.topAnchor.constraint(equalTo: imageView.topAnchor),
            rightView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rightViewWidth
        ])
        
        leftView.isUserInteractionEnabled = true
        rightView.isUserInteractionEnabled = true
        imageView.isUserInteractionEnabled = true
        leftView.backgroundColor = .clear
        rightView.backgroundColor = .clear
        
        let LeftswipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
        LeftswipeUp.direction = .up
        leftView.addGestureRecognizer(LeftswipeUp)
        
        let LeftswipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
        LeftswipeDown.direction = .down
        leftView.addGestureRecognizer(LeftswipeDown)
        
        let LeftswipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
        LeftswipeLeft.direction = .left
        leftView.addGestureRecognizer(LeftswipeLeft)
        
        let LeftswipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
        LeftswipeRight.direction = .right
        leftView.addGestureRecognizer(LeftswipeRight)
        
        
        let RightswipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRightGesture(_:)))
        RightswipeUp.direction = .up
        rightView.addGestureRecognizer(RightswipeUp)
        
        let RightswipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRightGesture(_:)))
        RightswipeDown.direction = .down
        rightView.addGestureRecognizer(RightswipeDown)
        
        let RightswipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRightGesture(_:)))
        RightswipeLeft.direction = .left
        rightView.addGestureRecognizer(RightswipeLeft)
        
        let RightswipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRightGesture(_:)))
        RightswipeRight.direction = .right
        rightView.addGestureRecognizer(RightswipeRight)
        
        // Create navigation items
        saveButton.isEnabled = false
        intensitySlider.minimumValue = 0
        intensitySlider.maximumValue = 1
        intensitySlider.value = 0.5
        intensitySlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        intensitySlider.isHidden = true
    }
    @objc func sliderValueChanged(_ slider: UISlider) {
        print("Slider value changing")
        DispatchQueue.main.async {
            
            self.firstMetalView.draw()
        }
        // Call your custom function or perform any desired actions here
    }
    
    func setupCoreImage(){
        ciContext = CIContext(mtlDevice: metalDevice)
    }
    
    @objc func handleSwipeLeftGesture(_ gesture: UISwipeGestureRecognizer) {
        let bounds = firstMetalView.drawableSize
            if gesture.direction == .up {
                // Handle swipe up
                intensitySliderValueSet = false
                leftFilterIndex += 1
                if leftFilterIndex == leftFilters?.count{
                    leftFilterIndex = 0
                }
                feedbackGenerator?.selectionChanged()
                print("left up")
                
            } else if gesture.direction == .down {
                // Handle swipe down
                intensitySliderValueSet = false
                intensitySliderValueSet = false
                leftFilterIndex -= 1
                if leftFilterIndex == -1{
                    leftFilterIndex = (leftFilters?.count ?? 1) - 1
                }
                feedbackGenerator?.selectionChanged()
                print("left down")
            } else if gesture.direction == .left {
                // Handle swipe left
                print("left left")
                if isLeftExpanded{
                    leftRect = CGRect(x: 0, y: 0, width: bounds.width/2, height: bounds.height)
                    rightRect = CGRect(x: bounds.width/2, y: 0, width: bounds.width/2, height: bounds.height)
                    leftViewWidth.constant = 0
                    rightView.isHidden = false
                    isLeftExpanded = false
                    intensitySliderValueSet = false
                    feedbackGenerator?.selectionChanged()
                        self.view.layoutIfNeeded()
                    
                }
            } else if gesture.direction == .right {
                // Handle swipe right
                print("left right")
                if !isLeftExpanded{
                    leftRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
                    rightRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                    leftViewWidth.constant = imageView.bounds.width/2
                    rightView.isHidden = true
                    isLeftExpanded = true
                    intensitySliderValueSet = false
                    feedbackGenerator?.selectionChanged()
                        self.view.layoutIfNeeded()
                    
                }
            }
        if isLeftExpanded{
            saveButton.isEnabled = true
        }
        else{
            saveButton.isEnabled = false
        }
        DispatchQueue.main.async {
            
            self.firstMetalView.draw()
        }
    }
    
    @objc func handleSwipeRightGesture(_ gesture: UISwipeGestureRecognizer) {
        let bounds = firstMetalView.drawableSize
            if gesture.direction == .up {
                // Handle swipe up
                rightFilterIndex += 1
                intensitySliderValueSet = false
                if rightFilterIndex == rightFilters?.count{
                    rightFilterIndex = 0
                }
                feedbackGenerator?.selectionChanged()
                print("right up")
            } else if gesture.direction == .down {
                // Handle swipe down
                rightFilterIndex -= 1
                intensitySliderValueSet = false
                if rightFilterIndex == -1 {
                    rightFilterIndex = (rightFilters?.count ?? 1) - 1
                }
                feedbackGenerator?.selectionChanged()
                print("right down")
            } else if gesture.direction == .left {
                // Handle swipe left
                print("right left")
                if !isRightExpanded{
                    rightRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
                    leftRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                    rightViewWidth.constant = imageView.bounds.width/2
                    leftView.isHidden = true
                    isRightExpanded = true
                    intensitySliderValueSet = false
                    feedbackGenerator?.selectionChanged()
                        self.view.layoutIfNeeded()
                    
                }
            } else if gesture.direction == .right {
                // Handle swipe right
                print("right right")
                if isRightExpanded{
                    leftRect = CGRect(x: 0, y: 0, width: bounds.width/2, height: bounds.height)
                    rightRect = CGRect(x: bounds.width/2, y: 0, width: bounds.width/2, height: bounds.height)
                    rightViewWidth.constant = 0
                    leftView.isHidden = false
                    isRightExpanded = false
                    intensitySliderValueSet = false
                    feedbackGenerator?.selectionChanged()
                        self.view.layoutIfNeeded()
                }
                
            }
        if isRightExpanded{
            saveButton.isEnabled = true
        }
        else{
            saveButton.isEnabled = false
        }
        DispatchQueue.main.async {
            
            self.firstMetalView.draw()
        }
        }

    @objc func saveButtonTapped() {
        guard let filteredCIImage = filteredCIImage else { return }
        let context = self.ciContext
        guard let cgImage = context?.createCGImage(filteredCIImage, from: filteredCIImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        saveImage(image: uiImage, albumName: albumName)
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
     @objc func backButtonTapped() {
         dismiss(animated: true, completion: {
             self.delegate?.startRunningCamera()
         })
     }
     
     func imageLoaded() {
         // This function is called when the image is loaded
         print("Image loaded")
         if let ciImage = image.ciImage {
             // The UIImage has a valid CIImage representation
             // Use ciImage for further processing
             predictUsingVision(ciImage: ciImage)
             self.ciImage = ciImage
             
         } else if let cgImage = image.cgImage {
             // Create a CIImage from the CGImage
             let ciImage = CIImage(cgImage: cgImage)
             // Use ciImage for further processing
             predictUsingVision(ciImage: ciImage)
             self.ciImage = ciImage
         } else {
             // Unable to obtain a CIImage from the UIImage
             // Handle the error case
             print("Unable to create CIImage from the UIImage.")
         }
         
         DispatchQueue.main.async {
             
             self.firstMetalView.draw()
         }

         
     }
     
     private func showAlert(withTitle title: String, message: String) {
         let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
         present(alert, animated: true, completion: nil)
     }
    
    func loadModel() {
        guard let objectDectectionModel = objectDectectionModel else { fatalError("fail to load the model") }
        if let visionModel = try? VNCoreMLModel(for: objectDectectionModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
            
        } else {
            fatalError("fail to create vision model")
        }
    }
    
    func predictUsingVision(ciImage: CIImage) {
        guard let request = request else {
            print("Error: Vision request is not properly initialized.")
            return
        }
        
        do {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try handler.perform([request])
        } catch {
            print("Error: \(error)")
        }
    }
    
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let predictions = request.results as? [VNRecognizedObjectObservation] {
            //            print(predictions.first?.labels.first?.identifier ?? "nil")
            //            print(predictions.first?.labels.first?.confidence ?? -1)
            self.predictions = predictions
            DispatchQueue.main.async {
                self.boxesView.predictedObjects = predictions
                // end of measure
                
                self.semaphore.signal()
            }
            
        }
    }
    
    func setFiltersForScene(sceneLabel: String) {
        // Find the scene in globalScenesArray that matches the scene label
        if let scene = globalScenesArray.first(where: { $0.label == sceneLabel }) {
            // Set the left and right filters for this scene
            leftFilters = scene.leftFilters
            rightFilters = scene.rightFilters

            // Just for testing, print the first filter name for left and right
        } else {
            print("Scene \(sceneLabel) not found")
        }
    }
    
    func setAllFilters(){
        let allFilters: [Filter] = globalScenesArray.flatMap { $0.leftFilters + $0.rightFilters }
        leftFilters = allFilters
    
    }
    
    func loadFilterData() {
        if let url = Bundle.main.url(forResource: "Filters", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let jsonData = try decoder.decode(Filters.self, from: data)
                globalScenesArray = jsonData.scenes
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func setupMetal(){
        //fetch the default gpu of the device (only one on iOS devices)
        metalDevice = MTLCreateSystemDefaultDevice()
        let metalFrame = UIView()
        metalFrame.translatesAutoresizingMaskIntoConstraints = false
        imageView.addSubview(metalFrame)
        NSLayoutConstraint.activate([
            metalFrame.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            metalFrame.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            metalFrame.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            metalFrame.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
        ])
    
        view.layoutIfNeeded()
        firstMetalView = MTKView(frame: metalFrame.frame, device: metalDevice)
        //tell our MTKView which gpu to use
        //tell our MTKView to use explicit drawing meaning we have to call .draw() on it
        firstMetalView.isPaused = true
        firstMetalView.enableSetNeedsDisplay = false
        firstMetalView.contentMode = .center
        //create a command queue to be able to send down instructions to the GPU
        metalCommandQueue = metalDevice.makeCommandQueue()
        
        //conform to our MTKView's delegate
        firstMetalView.delegate = self
        //let it's drawable texture be writen to
        firstMetalView.framebufferOnly = false
        firstMetalView.contentMode = .scaleAspectFit
        imageView.addSubview(firstMetalView)
        imageView.bringSubviewToFront(leftView)
        imageView.bringSubviewToFront(rightView)
        imageView.bringSubviewToFront(intensitySlider)
        let bounds = firstMetalView.drawableSize
        leftRect = CGRect(x: 0, y: 0, width: bounds.width/2, height: bounds.height)
        rightRect = CGRect(x: bounds.width/2, y: 0, width: bounds.width/2, height: bounds.height)
        
    }

}


extension GalleryViewController: DrawingBoundingBoxViewDelegate{
    func sceneDetected(scene: String?) {
        if let scene = scene{
            if let prevScene = storedScene{
                if prevScene != scene{
                    intensitySliderValueSet = false
                    storedScene = scene
                    setFiltersForScene(sceneLabel: scene)
                    rightFilterIndex = 0
                    leftFilterIndex = 0
                }
            }
            else{
                intensitySliderValueSet = false
                storedScene = scene
                setFiltersForScene(sceneLabel: scene)
                rightFilterIndex = 0
                leftFilterIndex = 0
            }
            
            UIView.animate(withDuration: 0.3) { [self] in
                sceneLabel.text = scene.capitalized
            }
            
        }
        else{
            // no scene detected
            let dummySwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
            dummySwipeGesture.direction = .right
            handleSwipeLeftGesture(dummySwipeGesture)
            setAllFilters()
        }
    }
}


extension GalleryViewController: MTKViewDelegate{
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
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("Hello")
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
    
    
    
}
