import UIKit

extension UIImage {
    /// Returns a copy of the image drawn in `.up` orientation,
    /// stripping EXIF rotation metadata so backends/CDNs display it correctly.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalized ?? self
    }
}
