// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

class KNWalletQRCodeViewController: KNBaseViewController {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var qrcodeImageView: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!

  @IBOutlet weak var copyWalletButton: UIButton!
  @IBOutlet weak var shareButton: UIButton!

  fileprivate var viewModel: KNWalletQRCodeViewModel

  init(viewModel: KNWalletQRCodeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNWalletQRCodeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupWalletData()
    self.setupButtons()
  }

  fileprivate func setupWalletData() {
    self.titleLabel.text = self.viewModel.wallet.name
    self.addressLabel.text = self.viewModel.displayedAddress
    let text = self.viewModel.address
    DispatchQueue.global(qos: .background).async {
      let image = UIImage.generateQRCode(from: text)
      DispatchQueue.main.async {
        self.qrcodeImageView.image = image
      }
    }
  }

  fileprivate func setupButtons() {
    self.copyWalletButton.rounded(radius: self.copyWalletButton.frame.height / 2.0)
    self.copyWalletButton.setTitle(self.viewModel.copyAddressBtnTitle, for: .normal)
    self.shareButton.rounded(
      color: UIColor(red: 202, green: 208, blue: 223),
      width: 1.0,
      radius: self.shareButton.frame.height / 2.0
    )
    self.shareButton.setTitle(self.viewModel.shareBtnTitle, for: .normal)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func copyWalletButtonPressed(_ sender: Any) {
    UIPasteboard.general.string = self.viewModel.address

    let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
    hud.mode = .text
    hud.label.text = "Address copied".toBeLocalised()
    hud.hide(animated: true, afterDelay: 1.5)
  }

  @IBAction func shareButtonPressed(_ sender: UIButton) {
    let activityItems: [Any] = {
      var items: [Any] = []
      items.append(self.viewModel.shareText)
      if let image = self.qrcodeImageView.image { items.append(image) }
      return items
    }()
    let activityViewController = UIActivityViewController(
      activityItems: activityItems,
      applicationActivities: nil
    )
    activityViewController.popoverPresentationController?.sourceView = sender
    self.present(activityViewController, animated: true, completion: nil)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.navigationController?.popViewController(animated: true)
    }
  }
}
