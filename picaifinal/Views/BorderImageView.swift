import UIKit

class BorderImageView: UIImageView {
    override var image: UIImage? {
        didSet {
            // Update the border when the image is set
            if image != nil {
                layer.borderWidth = 1.0
                layer.borderColor = UIColor.white.cgColor
                layer.cornerRadius = 10.0
                clipsToBounds = true
            } else {
                // Remove the border if the image is nil
                layer.borderWidth = 0.0
                layer.borderColor = nil
                layer.cornerRadius = 0.0
                clipsToBounds = false
            }
        }
    }
}
