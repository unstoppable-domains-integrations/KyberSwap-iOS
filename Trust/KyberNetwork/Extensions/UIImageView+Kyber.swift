// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIImageView {
  func setImage(with url: URL, placeholder: UIImage?) {
    self.image = placeholder
    URLSession.shared.dataTask(with: url) { (data, _, error) in
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          self.image = image
        }
      }
    }.resume()
  }

  func setImage(with urlString: String, placeholder: UIImage?) {
    self.image = placeholder
    guard let url = URL(string: urlString) else { return }
    self.setImage(with: url, placeholder: placeholder)
  }
}
