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
    
    //MARK: CAMERA INITIALIZE
    var wideCamera : AVCaptureDevice?
    var ultraWideCamera : AVCaptureDevice?
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
    var currentCamera: AVCaptureDevice?
    var currentZoomFactor: CGFloat = 1.0
    
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
//        setupCaptureSession()
        
        
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
        startRunningCaptureSession()
        setupCameras()
        setUpModel()
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

