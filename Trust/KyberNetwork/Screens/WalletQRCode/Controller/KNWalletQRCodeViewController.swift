// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import MBProgressHUD

class KNWalletQRCodeViewController: KNBaseViewController {

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
    self.setupNavigationBar()
    self.setupWalletData()
    self.setupButtons()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = self.viewModel.navigationTitle
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(self.leftBarButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupWalletData() {
    self.addressLabel.text = self.viewModel.address
    let text = self.viewModel.address
    DispatchQueue.global(qos: .background).async {
      let image = UIImage.generateQRCode(from: text)
      DispatchQueue.main.async {
        self.qrcodeImageView.image = image
      }
    }
  }

  fileprivate func setupButtons() {
    self.copyWalletButton.rounded(radius: 4.0)
    self.copyWalletButton.setTitle(self.viewModel.copyAddressBtnTitle, for: .normal)
    self.shareButton.rounded(radius: 4.0)
    self.shareButton.setTitle(self.viewModel.shareBtnTitle, for: .normal)
  }

  @objc func leftBarButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
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
}
