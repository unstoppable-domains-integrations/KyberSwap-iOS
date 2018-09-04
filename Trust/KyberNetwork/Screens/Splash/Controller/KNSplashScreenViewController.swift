// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNSplashScreenViewController: UIViewController {

  @IBOutlet weak var splashLogoImageView: UIImageView!
  @IBOutlet weak var debugInfoView: UIView!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var networkLabel: UILabel!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = KNAppStyleType.current.landingBackgroundColor
    //TODO: Remove in prod build
    //self.debugInfoView.isHidden = isDebug
    self.versionLabel.text = "Version: \(Bundle.main.versionNumber ?? "")"
    self.networkLabel.text = "Network: \(KNEnvironment.default.displayName)"
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.splashLogoImageView.isHidden = false
  }

  func rotateSplashLogo(duration: TimeInterval, completion: @escaping () -> Void) {
    self.splashLogoImageView.rotate360Degrees(duration: duration, completion: completion)
  }

  func moveSplashLogoAnimation(completion: @escaping () -> Void) {
    // Just rotate logo for fun here
    self.rotateSplashLogo(duration: 1.0) {
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: {
        let imageView = UIImageView(frame: self.splashLogoImageView.frame)
        imageView.image = self.splashLogoImageView.image
        self.view.addSubview(imageView)
        self.splashLogoImageView.isHidden = true

        //swiftlint:disable multiple_closures_with_trailing_closure
        UIView.animate(withDuration: 0.5, animations: {
          imageView.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
          imageView.center = CGPoint(x: 25, y: 85) }) { _ in
            imageView.removeFromSuperview()
            completion()
        }
      })
    }
  }
}
