// Copyright SIX DAY LLC. All rights reserved.

import UIKit

@objc protocol KNWalletHeaderViewDelegate: class {
  func walletHeaderScanQRCodePressed(wallet: KNWalletObject, sender: KNWalletHeaderView)
  func walletHeaderWalletListPressed(wallet: KNWalletObject, sender: KNWalletHeaderView)
  @objc optional func walletHeaderDebugButtonPressed(sender: KNWalletHeaderView)
}

struct KNWalletHeaderViewModel {
  var type = KNAppTracker.walletHeaderView()

  init() {}

  mutating func updateType() {
    self.type = KNAppTracker.walletHeaderView()
  }

  var backgroundColor: UIColor {
    return type == "white" ? UIColor.white : UIColor(hex: "09281f")
  }

  var tintColor: UIColor {
    return type == "white" ? UIColor(hex: "09281f") : UIColor.white
  }

  var barcodeIcon: String {
    return type == "white" ? "barcode_black" : "barcode_white"
  }

  var walletListIcon: String {
    return type == "white" ? "burger_menu_black" : "burger_menu"
  }

  var walletAddressAttributes: [NSAttributedStringKey: Any] {
    return [NSAttributedStringKey.foregroundColor: self.type == "white" ? UIColor(hex: "09281f") : UIColor(hex: "c4c4c4"),
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium),
    ]
  }

  var walletNameAttributes: [NSAttributedStringKey: Any] {
    return [NSAttributedStringKey.foregroundColor: self.type == "white" ? UIColor(hex: "09281f") : UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium),
    ]
  }
}

class KNWalletHeaderView: XibLoaderView {
  @IBOutlet var containerView: UIView!
  @IBOutlet weak var walletIconImageView: UIImageView!
  @IBOutlet weak var walletInfoLabel: UILabel!
  @IBOutlet weak var debugButton: UIButton!
  @IBOutlet weak var qrcodeButton: UIButton!
  @IBOutlet weak var walletListButton: UIButton!

  @IBOutlet weak var pendingTxNotiView: UIView!

  weak var delegate: KNWalletHeaderViewDelegate?
  fileprivate var viewModel = KNWalletHeaderViewModel()

  fileprivate var wallet: KNWalletObject?

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: NSNotification.Name(rawValue: kWalletHeaderViewDidChangeTypeNotificationKey),
      object: nil
    )
  }

  override func commonInit() {
    super.commonInit()
    self.walletInfoLabel.text = ""
    self.pendingTxNotiView.rounded(radius: self.pendingTxNotiView.frame.width / 2.0)
    self.pendingTxNotiView.isHidden = true
    self.updateUI()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(self.walletHeaderViewTypeDidChange(_:)),
      name: NSNotification.Name(rawValue: kWalletHeaderViewDidChangeTypeNotificationKey),
      object: nil
    )
  }

  fileprivate func updateUI() {
    self.containerView.backgroundColor = self.viewModel.backgroundColor
    self.walletIconImageView.rounded(
      color: self.viewModel.tintColor,
      width: 1,
      radius: self.walletIconImageView.frame.width / 2.0
    )
    self.walletInfoLabel.textColor = self.viewModel.tintColor
    // change tint color is not working properly
    self.qrcodeButton.setImage(UIImage(named: self.viewModel.barcodeIcon), for: .normal)
    self.walletListButton.setImage(UIImage(named: self.viewModel.walletListIcon), for: .normal)

    self.debugButton.setTitleColor(self.viewModel.tintColor, for: .normal)
    self.layoutIfNeeded()
  }

  func updateView(with wallet: KNWalletObject) {
    self.wallet = wallet
    self.walletIconImageView.image = UIImage(named: wallet.icon)
    let address = "\(wallet.address.prefix(7))......\(wallet.address.suffix(5))"
    self.walletInfoLabel.attributedText = {
      let attributedString = NSMutableAttributedString()
      attributedString.append(NSAttributedString(string: address, attributes: self.viewModel.walletAddressAttributes))
      attributedString.append(NSAttributedString(string: "\n\(wallet.name)", attributes: self.viewModel.walletNameAttributes))
      return attributedString
    }()
  }

  func updateBadgeCounter(_ number: Int) {
    self.pendingTxNotiView.isHidden = number == 0
  }

  @IBAction func scanQRCodePressed(_ sender: Any) {
    guard let wallet = self.wallet else { return }
    self.delegate?.walletHeaderScanQRCodePressed(wallet: wallet, sender: self)
  }

  @IBAction func walletListButtonPressed(_ sender: Any) {
    guard let wallet = self.wallet else { return }
    self.delegate?.walletHeaderWalletListPressed(wallet: wallet, sender: self)
  }

  @IBAction func debugButtonPressed(_ sender: Any) {
    self.delegate?.walletHeaderDebugButtonPressed?(sender: self)
  }

  // MARK: For debugging only
  @objc func walletHeaderViewTypeDidChange(_ sender: Notification) {
    self.viewModel.updateType()
    self.updateUI()
  }
}
