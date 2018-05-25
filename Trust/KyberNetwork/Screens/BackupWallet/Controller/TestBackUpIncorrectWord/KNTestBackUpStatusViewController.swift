// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNTestBackUpStatusViewControllerDelegate: class {
  func testBackUpStatusViewDidPressSecondButton(sender: KNTestBackUpStatusViewController)
  func testBackUpStatusViewDidComplete(sender: KNTestBackUpStatusViewController)
}

struct KNTestBackUpStatusViewModel {
  let isSuccess: Bool
  let isFirstTime: Bool

  init(isFirstTime: Bool, isSuccess: Bool) {
    self.isFirstTime = isFirstTime
    self.isSuccess = isSuccess
  }

  var backgroundColor: UIColor {
    return self.isSuccess ? UIColor(hex: "395497") : UIColor.black.withAlphaComponent(0.5)
  }

  var isContainerViewHidden: Bool {
    return self.isSuccess
  }

  var isSuccessViewHidden: Bool {
    return !self.isSuccess
  }

  var title: String {
    return self.isFirstTime ? "Wrong Backup".toBeLocalised() : "Wrong Again".toBeLocalised()
  }

  var message: String {
    return self.isFirstTime ? "Your backup words are incorrect. Please try again.".toBeLocalised() : "You entered the wrong backup words for another time. Want to backup again?".toBeLocalised()
  }

  var numberButtons: Int {
    return self.isFirstTime ? 1 : 2
  }

  var firstButtonTitle: String {
    return self.isFirstTime ? "Try Again".toBeLocalised() : "Retry".toBeLocalised()
  }

  var firstButtonColorHex: String {
    return self.isFirstTime ? "5ec2ba" : "aaaaaa"
  }

  var secondButtonTitle: String {
    return "Backup Again".toBeLocalised()
  }

  var secondButtonColorHex: String {
    return "5ec2ba"
  }
}

class KNTestBackUpStatusViewController: KNBaseViewController {

  @IBOutlet weak var containerView: UIView!

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var messageLabel: UILabel!

  @IBOutlet weak var firstButton: UIButton!
  @IBOutlet weak var secondButton: UIButton!

  @IBOutlet weak var secondButtonWidthConstraint: NSLayoutConstraint!

  @IBOutlet weak var successContainerView: UIView!

  fileprivate var viewModel: KNTestBackUpStatusViewModel
  weak var delegate: KNTestBackUpStatusViewControllerDelegate?

  init(viewModel: KNTestBackUpStatusViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTestBackUpStatusViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = self.viewModel.backgroundColor
    self.containerView.rounded(radius: 10.0)
    self.containerView.isHidden = self.viewModel.isContainerViewHidden
    self.titleLabel.text = self.viewModel.title
    self.messageLabel.text = self.viewModel.message

    self.firstButton.setTitle(self.viewModel.firstButtonTitle, for: .normal)
    self.firstButton.backgroundColor = UIColor(hex: self.viewModel.firstButtonColorHex)

    self.secondButton.setTitle(self.viewModel.secondButtonTitle, for: .normal)
    self.secondButton.backgroundColor = UIColor(hex: self.viewModel.secondButtonColorHex)

    if self.viewModel.numberButtons == 1 {
      self.secondButtonWidthConstraint.constant = 0
    } else {
      self.secondButtonWidthConstraint.constant = self.containerView.frame.width / 2.0
    }
    self.successContainerView.isHidden = self.viewModel.isSuccessViewHidden
    self.view.updateConstraints()
    if self.viewModel.isSuccess {
      Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false, block: { [weak self] _ in
        guard let `self` = self else { return }
        self.dismiss(animated: true) {
          self.delegate?.testBackUpStatusViewDidComplete(sender: self)
        }
      })
    }
  }

  @IBAction func firstButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func secondButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      self.delegate?.testBackUpStatusViewDidPressSecondButton(sender: self)
    }
  }
}
