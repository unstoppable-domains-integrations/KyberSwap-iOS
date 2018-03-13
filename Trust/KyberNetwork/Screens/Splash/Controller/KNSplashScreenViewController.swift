// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSplashScreenViewController: UIViewController {

  @IBOutlet weak var splashLogoImageView: UIImageView!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.white
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.splashLogoImageView.isHidden = false
  }

  func moveSplashLogoAnimation(completion: @escaping () -> Void) {
    let imageView = UIImageView(frame: self.splashLogoImageView.frame)
    imageView.image = self.splashLogoImageView.image
    self.view.addSubview(imageView)
    self.splashLogoImageView.isHidden = true

    UIView.animate(withDuration: 0.5, animations: {
      imageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
      imageView.center = CGPoint(x: 25, y: 85) }){ _ in
      imageView.removeFromSuperview()
      completion()
    }
  }
}
