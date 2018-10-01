// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNCreateWalletViewEvent {
  case back
  case next(name: String)
}

protocol KNCreateWalletViewControllerDelegate: class {
  func createWalletViewController(_ controller: KNCreateWalletViewController, run event: KNCreateWalletViewEvent)
}

class KNCreateWalletViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var confirmLabel: UILabel!
  @IBOutlet weak var descLabel: UILabel!
  @IBOutlet weak var confirmButton: UIButton!

  weak var delegate: KNCreateWalletViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    self.containerView.rounded(radius: 5.0)
    let style = KNAppStyleType.current
    self.confirmButton.rounded(radius: style.buttonRadius(for: self.confirmButton.frame.height))
    self.confirmButton.backgroundColor = style.createWalletButtonEnabledColor
    self.confirmButton.setTitle(
      style.buttonTitle(with: "Confirm".toBeLocalised()),
      for: .normal
    )

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let touchedPoint = sender.location(in: self.view)
    if touchedPoint.x < self.containerView.frame.minX
      || touchedPoint.x > self.containerView.frame.maxX
      || touchedPoint.y < self.containerView.frame.minY
      || touchedPoint.y > self.containerView.frame.maxY {
      self.delegate?.createWalletViewController(self, run: .back)
    }
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.delegate?.createWalletViewController(self, run: .next(name: "Untitled"))
  }
}
