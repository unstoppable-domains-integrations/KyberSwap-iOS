// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIImageView {
  func setImage(with url: URL, placeholder: UIImage?, size: CGSize? = nil, applyNoir: Bool = false) {
    self.image = applyNoir ? placeholder?.resizeImage(to: size)?.noir : placeholder?.resizeImage(to: size)
    URLSession.shared.dataTask(with: url) { (data, _, error) in
      if error == nil, let data = data, let image = UIImage(data: data) {
        DispatchQueue.main.async {
          self.image = applyNoir ? image.resizeImage(to: size)?.noir : image.resizeImage(to: size)
        }
      }
    }.resume()
  }

  func setImage(with urlString: String, placeholder: UIImage?, size: CGSize? = nil, applyNoir: Bool = false) {
    guard let url = URL(string: urlString) else {
      self.image = applyNoir ? placeholder?.resizeImage(to: size)?.noir : placeholder?.resizeImage(to: size)
      return
    }
    self.setImage(with: url, placeholder: placeholder, size: size, applyNoir: applyNoir)
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
