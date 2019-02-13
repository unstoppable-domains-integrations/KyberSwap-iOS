// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIImageView {
  func setImage(with url: URL, placeholder: UIImage?, size: CGSize? = nil) {
    self.image = placeholder?.resizeImage(to: size)
    URLSession.shared.dataTask(with: url) { (data, _, error) in
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          self.image = image.resizeImage(to: size)
        }
      }
    }.resume()
  }

  func setImage(with urlString: String, placeholder: UIImage?, size: CGSize? = nil) {
    guard let url = URL(string: urlString) else {
      self.image = placeholder?.resizeImage(to: size)
      return
    }
    self.setImage(with: url, placeholder: placeholder)
  }

  func setTokenImage(
    token: TokenObject,
    size: CGSize? = nil
    ) {
    let icon = token.icon.isEmpty ? token.symbol.lowercased() : token.icon
    if let image = UIImage(named: icon.lowercased()) {
      self.image = image.resizeImage(to: size)
    } else {
      let placeHolderImg = UIImage(named: "default_token")
      self.setImage(
        with: token.iconURL,
        placeholder: placeHolderImg,
        size: size
      )
    }
  }
}
