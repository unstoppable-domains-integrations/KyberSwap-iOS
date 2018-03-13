// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletImportingMainViewControllerDelegate: class {
  func walletImportingMainScreenUserDidClickImportAddressByKeystore()
  func walletImportingMainScreenUserDidClickImportAddressByPrivateKey()
}

class KNWalletImportingMainViewController: UIViewController {

  fileprivate weak var delegate: KNWalletImportingMainViewControllerDelegate?

  @IBOutlet weak var importWalletLabel: UILabel!

  @IBOutlet weak var keystoreButton: UIButton!
  @IBOutlet weak var keystoreLabel: UILabel!

  @IBOutlet weak var privateKeyButton: UIButton!
  @IBOutlet weak var privateKeyLabel: UILabel!

  init(delegate: KNWalletImportingMainViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNWalletImportingMainViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NSLog("Did open: \(self.className)")
  }

  fileprivate func setupUI() {
    self.applyBaseGradientBackground()
    self.navigationController?.isNavigationBarHidden = true
    self.importWalletLabel.text = "Import Address".toBeLocalised()

    self.keystoreButton.rounded(color: .clear, width: 0, radius: 10.0)
    self.keystoreLabel.text = "JSON\nKeystore".toBeLocalised()
    self.keystoreLabel.numberOfLines = 2

    self.privateKeyButton.rounded(color: .clear, width: 0, radius: 10.0)
    self.privateKeyLabel.text = "Private Key".toBeLocalised()
  }

  @IBAction func keystoreButtonPressed(_ sender: Any) {
    self.delegate?.walletImportingMainScreenUserDidClickImportAddressByKeystore()
  }

  @IBAction func privateKeyButtonPressed(_ sender: Any) {
    self.delegate?.walletImportingMainScreenUserDidClickImportAddressByPrivateKey()
  }
}
