//
//  Gestures.swift
//  picaifinal
//
//  Created by AppleMini on 20/06/23.
//

import UIKit

extension ViewController {
    
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

}
