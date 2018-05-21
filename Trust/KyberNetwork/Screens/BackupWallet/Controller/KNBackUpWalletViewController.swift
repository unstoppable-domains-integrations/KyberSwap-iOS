// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNBackUpWalletViewControllerDelegate: class {
  func backupWalletViewControllerDidFinish()
}

class KNBackUpWalletViewController: KNBaseViewController {

  weak var delegate: KNBackUpWalletViewControllerDelegate?
  fileprivate var viewModel: KNBackUpWalletViewModel

  fileprivate let defaultTime: Int = isDebug ? 5 : 15
  fileprivate var timeLeft: Int = 15

  @IBOutlet weak var backupWalletLabel: UILabel!
  @IBOutlet weak var titlelabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var writeDownWordsTextLabel: UILabel!

  @IBOutlet var wordLabels: [UILabel]!

  @IBOutlet weak var wroteDownButton: UIButton!

  init(viewModel: KNBackUpWalletViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNBackUpWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.backupWalletLabel.text = self.viewModel.backUpWalletText
    self.wroteDownButton.setBackgroundColor(.lightGray, forState: .disabled)
    self.wroteDownButton.setBackgroundColor(UIColor(hex: "5ec2ba"), forState: .normal)
    self.updateUI()
  }

  fileprivate func updateUI() {
    UIView.animate(
      withDuration: 0.25,
      delay: 0,
      options: UIViewAnimationOptions.curveEaseInOut,
      animations: {
        self.backupWalletLabel.text = self.viewModel.backUpWalletText
        self.titlelabel.text = self.viewModel.titleText
        self.descriptionLabel.text = self.viewModel.descriptionText
        self.writeDownWordsTextLabel.text = self.viewModel.writeDownWordsText
        self.timeLeft = self.defaultTime
        self.wroteDownButton.setTitle("\(self.timeLeft) second(s)", for: .disabled)
        self.wroteDownButton.isEnabled = false

        for id in 0..<self.viewModel.numberWords {
          let label = self.wordLabels.first(where: { $0.tag == id })
          label?.attributedText = self.viewModel.attributedString(for: id)
        }
      }, completion: nil
    )

    self.updateWroteDownButton()
  }

  fileprivate func updateWroteDownButton() {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
      self.timeLeft -= 1
      if self.timeLeft > 0 {
        self.wroteDownButton.setTitle("\(self.timeLeft) second(s)", for: .disabled)
        self.updateWroteDownButton()
      } else {
        self.wroteDownButton.setTitle(self.viewModel.wroteDownButtonTitle, for: .normal)
        self.wroteDownButton.isEnabled = true
      }
    }
  }

  @IBAction func wroteDownButtonPressed(_ sender: UIButton) {
    if self.viewModel.updateNextBackUpWords() {
      self.delegate?.backupWalletViewControllerDidFinish()
    } else {
      self.updateUI()
    }
  }
}
