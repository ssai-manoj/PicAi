//
//  Yolo.swift
//  picaifinal
//
//  Created by AppleMini on 20/06/23.
//

import UIKit
import Vision

extension ViewController {
    
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
