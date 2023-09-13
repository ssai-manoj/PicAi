//
//  ViewController.swift
//  picaifinal
//
//  Created by AppleMini on 30/05/23.
//

import UIKit
import AVFoundation
import Vision
import Metal
import MetalKit
import VisionKit
import Photos



class ViewController: UIViewController, DrawingBoundingBoxViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GalleryViewControllerDelegate, ImageViewControllerDelegate{
    
    
    var audioPlayer: AVAudioPlayer?
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var capturePhotoOutput: AVCapturePhotoOutput?
    var backCamera : AVCaptureDevice!
    var frontCamera : AVCaptureDevice!
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    var videoOutput : AVCaptureVideoDataOutput!
    lazy var objectDectectionModel = { return try? YOLOv3() }()
    var boxesView: DrawingBoundingBoxView = DrawingBoundingBoxView()
    let semaphore = DispatchSemaphore(value: 1)
    var predictions: [VNRecognizedObjectObservation] = []
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
    var takePicture = false
    var backCameraOn = true
    // MARK: core image
    var ciImage: CIImage?
    var ciContext: CIContext!
    var filteredCIImage: CIImage?
    var filteredUIImage: UIImage!
    var originalUIImage: UIImage!
    var frameCounter = 0
    var storedCVBuffer: CVImageBuffer?
    // MARK: Metal setup
    var metalDevice : MTLDevice!
    var metalCommandQueue : MTLCommandQueue!
    var intensitySliderValueSet = false
    // MARK: UI
    var videoPreviewContainerView: UIView!
    var firstMetalView: MTKView!
    var feedbackGenerator: UISelectionFeedbackGenerator?
    var leftRect: CGRect!
    var rightRect: CGRect!
    let zoomControl = UISegmentedControl(items: ["0.5x","1x","2x"])
    var leftView = UIView()
    var rightView = UIView()
    var captureButton: UIButton = UIButton()
    var cameraControls: UIView = UIView()
    let switchCamera = UIButton()
    var sceneLabel: UILabel = UILabel()
    var storedScene: String?
    var isFrameCaptured = false
    let galleryButton = UIButton()
    let filteredImageView = BorderImageView()
    //MARK: Filters
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
    
    //MARK: Misc
    var activityIndicator: UIActivityIndicatorView!
    var isAutomaticDetect = UserSettings.shared.isAutomaticDetect
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        boxesView.delegate = self
        checkPermissions()
        setupUI()
        setupMetal()
        setupAndStartCaptureSession()
        loadFilterData()
        
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        activityIndicator.color = .white
        // Add the activity indicator to the view hierarchy
        view.addSubview(activityIndicator)
        
        feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator?.prepare()
        galleryButton.isEnabled = false
        switchCamera.isEnabled = false
        zoomControl.isEnabled = false
        
        guard let soundURL = Bundle.main.url(forResource: "shutterSound", withExtension: "mp3") else {
                return
        }
        do {
                
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
                try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading shutter sound: \(error.localizedDescription)")
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupCoreImage()
        setupPreviewLayer()
        setUpModel()
        startRunningCaptureSession()
        zoomChanged(zoomControl)
        activityIndicator.stopAnimating()
        galleryButton.isEnabled = true
        switchCamera.isEnabled = true
        zoomControl.isEnabled = true
    }
    
    func setupUI(){
        
        view.backgroundColor = .black
        
        let detectControl = UISegmentedControl(items: ["Auto", "Manual"])
        if isAutomaticDetect{
            detectControl.selectedSegmentIndex = 0
        } else{
            detectControl.selectedSegmentIndex = 1
        }
        
        view.isUserInteractionEnabled = true
        zoomControl.selectedSegmentIndex = 1
        videoPreviewContainerView = UIView()
        videoPreviewContainerView.translatesAutoresizingMaskIntoConstraints = false
        videoPreviewContainerView.backgroundColor = .clear
        view.addSubview(videoPreviewContainerView)
        videoPreviewContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        videoPreviewContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        videoPreviewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        videoPreviewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        cameraControls.translatesAutoresizingMaskIntoConstraints = false
        zoomControl.translatesAutoresizingMaskIntoConstraints = false
        galleryButton.translatesAutoresizingMaskIntoConstraints = false
        detectControl.translatesAutoresizingMaskIntoConstraints = false
        switchCamera.translatesAutoresizingMaskIntoConstraints = false
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        intensitySlider.translatesAutoresizingMaskIntoConstraints = false
        filteredImageView.translatesAutoresizingMaskIntoConstraints = false
        
        videoPreviewContainerView.addSubview(cameraControls)
        filteredImageView.contentMode = .scaleAspectFit
       
        
        view.addSubview(captureButton)
        view.addSubview(intensitySlider)
        view.addSubview(filteredImageView)
        
        cameraControls.addSubview(zoomControl)
        cameraControls.addSubview(galleryButton)
        cameraControls.addSubview(detectControl)
        cameraControls.addSubview(switchCamera)
        
        sceneLabel.font = UIFont.systemFont(ofSize: 36, weight: .black)
        sceneLabel.translatesAutoresizingMaskIntoConstraints = false
        videoPreviewContainerView.addSubview(sceneLabel)
        
        NSLayoutConstraint.activate([
            
            intensitySlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            intensitySlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            intensitySlider.bottomAnchor.constraint(equalTo: captureButton.topAnchor, constant: -16),
            
            cameraControls.topAnchor.constraint(equalTo: videoPreviewContainerView.topAnchor),
            cameraControls.leadingAnchor.constraint(equalTo: videoPreviewContainerView.leadingAnchor),
            cameraControls.trailingAnchor.constraint(equalTo: videoPreviewContainerView.trailingAnchor),
            cameraControls.heightAnchor.constraint(equalTo: videoPreviewContainerView.heightAnchor, multiplier: 0.13),
            
            zoomControl.centerXAnchor.constraint(equalTo: cameraControls.centerXAnchor),
            zoomControl.bottomAnchor.constraint(equalTo: cameraControls.bottomAnchor, constant: -6),
            
            galleryButton.leadingAnchor.constraint(equalTo: cameraControls.leadingAnchor, constant: 16),
            galleryButton.centerYAnchor.constraint(equalTo: cameraControls.centerYAnchor),
            galleryButton.widthAnchor.constraint(equalToConstant: 24),
            galleryButton.heightAnchor.constraint(equalToConstant: 24),
            
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            
            filteredImageView.heightAnchor.constraint(equalToConstant: 70),
            filteredImageView.widthAnchor.constraint(equalToConstant: 70),
            filteredImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            filteredImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            
            detectControl.centerXAnchor.constraint(equalTo: cameraControls.centerXAnchor),
            detectControl.bottomAnchor.constraint(equalTo: zoomControl.topAnchor, constant: -6),
            
            sceneLabel.centerXAnchor.constraint(equalTo: videoPreviewContainerView.centerXAnchor),
            sceneLabel.centerYAnchor.constraint(equalTo: videoPreviewContainerView.centerYAnchor),
            
            switchCamera.trailingAnchor.constraint(equalTo: cameraControls.trailingAnchor, constant: -16),
            switchCamera.centerYAnchor.constraint(equalTo: cameraControls.centerYAnchor),
            switchCamera.widthAnchor.constraint(equalToConstant: 24),
            switchCamera.heightAnchor.constraint(equalToConstant: 24)
            
        ])
        
        
        
        
        cameraControls.backgroundColor = .white.withAlphaComponent(0.3)
        
        
        
        
        leftView.translatesAutoresizingMaskIntoConstraints = false
        rightView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(leftView)
        view.addSubview(rightView)
        leftView.backgroundColor = .clear
        rightView.backgroundColor = .clear
        
        leftViewWidth = leftView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        rightViewWidth = rightView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5)
        
        NSLayoutConstraint.activate([
            leftView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftView.topAnchor.constraint(equalTo: cameraControls.bottomAnchor),
            leftView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leftViewWidth,
            
            rightView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightView.topAnchor.constraint(equalTo: cameraControls.bottomAnchor),
            rightView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rightViewWidth
        ])
        
        leftView.isUserInteractionEnabled = true
        rightView.isUserInteractionEnabled = true
        videoPreviewContainerView.isUserInteractionEnabled = true
//        let borderWidth: CGFloat = 100.0
//        let borderColor = UIColor.blue.cgColor
//
//        let borderLayer = CALayer()
//        borderLayer.backgroundColor = borderColor
//        borderLayer.frame = CGRect(x: leftView.frame.width - borderWidth, y: 0, width: borderWidth, height: leftView.frame.height)
//
//        leftView.layer.addSublayer(borderLayer)
        
        
        
        
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
        
        galleryButton.setImage(UIImage(systemName: "photo.artframe"), for: .normal)
        galleryButton.tintColor = .white
        galleryButton.addTarget(self, action: #selector(galleryButtonClicked(_:)), for: .touchUpInside)
        
        switchCamera.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        switchCamera.tintColor = .white
        
        zoomControl.tintColor = .white
        detectControl.tintColor = .white
        
        switchCamera.addTarget(self, action: #selector(switchCamera(_:)), for: .touchDown)
        
        zoomControl.addTarget(self, action: #selector(zoomChanged(_:)), for: .valueChanged)
        detectControl.addTarget(self, action: #selector(detectControlChanged(_:)), for: .valueChanged)
        
        
        
        captureButton.setImage(UIImage(named: "circle"), for: .normal)
        captureButton.tintColor = .white
        captureButton.addTarget(self, action: #selector(captureButtonClicked(_:)), for: .touchUpInside)
        
        
        captureButton.isHidden = true
        intensitySlider.minimumValue = 0
        intensitySlider.maximumValue = 1
        intensitySlider.value = 0.5
        intensitySlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        intensitySlider.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        let imageViewtapGesture = UITapGestureRecognizer(target: self, action: #selector(imageViewTapped(_:)))
        filteredImageView.isUserInteractionEnabled = true
        filteredImageView.addGestureRecognizer(imageViewtapGesture)
        filteredImageView.isHidden = true
        view.layoutIfNeeded()
        //        firstMetalView.translatesAutoresizingMaskIntoConstraints = false
        //        firstMetalView.contentMode = .scaleToFill
        //
        //
        //        view.addSubview(firstMetalView)
        //
        //        NSLayoutConstraint.activate([
        //            firstMetalView.topAnchor.constraint(equalTo: view.topAnchor),
        //            firstMetalView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        //            firstMetalView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        //            firstMetalView.widthAnchor.constraint(equalTo: view.widthAnchor)
        //        ])
        //
        //        view.layoutIfNeeded()
    }
    
    @objc func imageViewTapped(_ sender: UITapGestureRecognizer) {
        // Instantiate the view controller you want to present
         print("Image View Tapped")
        let vc = ImageViewController()
        vc.filteredImage = filteredUIImage
        vc.originalImage = originalUIImage
        vc.delegate = self
        let navigationController = UINavigationController(rootViewController: vc)

        present(navigationController, animated: true, completion: {
            self.stopRunnigCaptureSession()
        })
    }
    
    @objc func detectControlChanged(_ sender: UISegmentedControl){
        let selectedSegmentIndex = sender.selectedSegmentIndex
        
        switch selectedSegmentIndex {
        case 0:
            print("Auto")
            isAutomaticDetect = true
            UserSettings.shared.isAutomaticDetect = true
        case 1:
            print("Manual")
            isAutomaticDetect = false
            UserSettings.shared.isAutomaticDetect = false
        default:
            break
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        // Call the function to handle the screen tap
        if !isAutomaticDetect{
            print("Screen Tapped")
            guard let cvBuffer = storedCVBuffer else { return }
            predictUsingVision(pixelBuffer: cvBuffer)
        }
        
    }
    
    @objc func sliderValueChanged(_ slider: UISlider) {
        print("Slider value changing")
        
        // Call your custom function or perform any desired actions here
    }
    
    @objc func zoomChanged(_ sender: UISegmentedControl){
        print("changing zoom to \(sender.selectedSegmentIndex)")
        let selectedSegmentIndex = sender.selectedSegmentIndex
        var zoomFactor: CGFloat = 2.0
        
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
    
    @objc func galleryButtonClicked(_ sender: UIButton){
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let selectedImage = info[.originalImage] as? UIImage {
                // Create an instance of ImageViewController
                let imageViewController = GalleryViewController()
                imageViewController.delegate = self
                imageViewController.image = selectedImage
                imageViewController.modalPresentationStyle = .overFullScreen
                // Present the ImageViewController
                self.present(imageViewController, animated: true, completion: { 
                    self.stopRunnigCaptureSession()
                })
            }
        }
    }
    
    func startRunningCamera() {
        startRunningCaptureSession()
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
    
    

    
    func sceneDetected(scene: String?) {
        if let scene = scene{
            print("Scene detected")
            
            
            
            if let prevScene = storedScene{
                if prevScene != scene{
                    intensitySliderValueSet = false
                    storedScene = scene
                    setFiltersForScene(sceneLabel: scene)
                    rightFilterIndex = 0
                    leftFilterIndex = 0
                    if isLeftExpanded{
                        let dummySwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
                        dummySwipeGesture.direction = .left
                        handleSwipeLeftGesture(dummySwipeGesture)
                        isLeftExpanded = false
                    }
                    if isRightExpanded{
                        let dummySwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRightGesture(_:)))
                        dummySwipeGesture.direction = .left
                        handleSwipeLeftGesture(dummySwipeGesture)
                        isRightExpanded = false
                    }
                }
            }
            else{
                intensitySliderValueSet = false
                storedScene = scene
                setFiltersForScene(sceneLabel: scene)
                rightFilterIndex = 0
                leftFilterIndex = 0
                if isLeftExpanded{
                    let dummySwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
                    dummySwipeGesture.direction = .left
                    handleSwipeLeftGesture(dummySwipeGesture)
                    isLeftExpanded = false
                }
            }
            
            UIView.animate(withDuration: 0.3) { [self] in
                sceneLabel.text = scene.capitalized
            }
        }
        else{
            //no scene detected
            storedScene = "nil"
            sceneLabel.text = nil
            let dummySwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeftGesture(_:)))
            dummySwipeGesture.direction = .right
            handleSwipeLeftGesture(dummySwipeGesture)
            setAllFilters()
        }
        
        
    }
    
    func setAllFilters(){
        let allFilters: [Filter] = globalScenesArray.flatMap { $0.leftFilters + $0.rightFilters }
        leftFilters = allFilters
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
                captureButton.isHidden = true
                feedbackGenerator?.selectionChanged()
                self.view.layoutIfNeeded()
                
            }
        } else if gesture.direction == .right {
            // Handle swipe right
            print("left right")
            if !isLeftExpanded{
                leftRect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
                rightRect = CGRect(x: 0, y: 0, width: 0, height: 0)
                leftViewWidth.constant = videoPreviewContainerView.bounds.width/2
                rightView.isHidden = true
                isLeftExpanded = true
                intensitySliderValueSet = false
                captureButton.isHidden = false
                view.bringSubviewToFront(captureButton)
                feedbackGenerator?.selectionChanged()
                self.view.layoutIfNeeded()
                
            }
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
                rightViewWidth.constant = videoPreviewContainerView.bounds.width/2
                leftView.isHidden = true
                isRightExpanded = true
                captureButton.isHidden = false
                intensitySliderValueSet = false
                view.bringSubviewToFront(captureButton)
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
                captureButton.isHidden = true
                feedbackGenerator?.selectionChanged()
                self.view.layoutIfNeeded()
            }
            
        }
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
            
            let hasUltraWideCamera: Bool = true // Set this variable to true if your device is one of the following - iPhone 11, iPhone 11 Pro, & iPhone 11 Pro Max
            
            if hasUltraWideCamera {
                
                // Your iPhone has UltraWideCamera.
                let deviceTypes: [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInUltraWideCamera]
                let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaType.video, position: position)
                return discoverySession.devices.first
                
            }
            
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
        //        view.layer.insertSublayer(videoPreviewLayer!, at: 0)
    }
    
    func setUpModel() {
        guard let objectDectectionModel = objectDectectionModel else { fatalError("fail to load the model") }
        if let visionModel = try? VNCoreMLModel(for: objectDectectionModel.model) {
            self.visionModel = visionModel
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request?.imageCropAndScaleOption = .scaleFill
        } else {
            fatalError("fail to create vision model")
        }
    }
    
    
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
    

}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
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

extension ViewController {
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        guard let request = request else {
            print("Error: Vision request is not properly initialized.")
            return
        }
        
        do {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try handler.perform([request])
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    
    // MARK: - Post-processing
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
}


extension ViewController{
    func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
        case .authorized:
            return
        case .denied:
            abort()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                                            { (authorized) in
                if(!authorized){
                    abort()
                }
            })
        case .restricted:
            abort()
        @unknown default:
            fatalError()
        }
    }
}

extension ViewController: MTKViewDelegate {
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
    
    
}
