//
//  ImageViewController.swift
//  picaifinal
//
//  Created by AppleMini on 15/06/23.
//

import UIKit

protocol ImageViewControllerDelegate {
    func startRunningCamera()
}

class ImageViewController: UIViewController {
    
    var filteredImage: UIImage!
    var originalImage: UIImage!
    var delegate: ImageViewControllerDelegate?
    
    let segmentedControl: UISegmentedControl = {
            let segmentedControl = UISegmentedControl(items: ["Processed", "Original"])
            segmentedControl.selectedSegmentIndex = 0
            segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            return segmentedControl
        }()
        
        let imageView: BorderImageView = {
            let imageView = BorderImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
    override func viewDidLoad() {
        super.viewDidLoad()

        super.viewDidLoad()
               
        overrideUserInterfaceStyle = .dark
        view.backgroundColor = .black
               
               view.addSubview(segmentedControl)
               view.addSubview(imageView)
               
               NSLayoutConstraint.activate([
                   segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
                   segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                   
                   imageView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 16),
                   imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                   imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                   imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
               ])
               
               // Set initial image
               updateImageView()
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.startRunningCamera()
    }
    
    @objc func segmentedControlValueChanged() {
            updateImageView()
        }
        
        func updateImageView() {
            if segmentedControl.selectedSegmentIndex == 0 {
                imageView.image = filteredImage
            } else {
                imageView.image = originalImage
            }
        }
    
    @objc func backButtonTapped() {
           dismiss(animated: true, completion: {
               self.delegate?.startRunningCamera()
           })
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
