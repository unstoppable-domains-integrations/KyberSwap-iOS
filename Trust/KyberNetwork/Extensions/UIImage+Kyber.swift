// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import JdenticonSwift

extension UIImage {
  static func generateQRCode(from string: String) -> UIImage? {
    let context = CIContext()
    let data = string.data(using: String.Encoding.ascii)

    if let filter = CIFilter(name: "CIQRCodeGenerator") {
      filter.setValue(data, forKey: "inputMessage")
      let transform = CGAffineTransform(scaleX: 7, y: 7)
      if let output = filter.outputImage?.transformed(by: transform), let cgImage = context.createCGImage(output, from: output.extent) {
        return UIImage(cgImage: cgImage)
      }
    }
    return nil
  }

  static func generateImage(with size: CGFloat, hash: Data) -> UIImage? {
    guard let cgImage = IconGenerator(size: size, hash: hash).render() else { return nil }
    return UIImage(cgImage: cgImage)
  }

  func resizeImage(to newSize: CGSize?) -> UIImage? {
    guard let size = newSize else { return self }
    if self.size == size { return self }

    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    self.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage ?? self
  }

}
