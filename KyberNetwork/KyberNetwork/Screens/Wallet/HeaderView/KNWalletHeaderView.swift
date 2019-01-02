// Copyright SIX DAY LLC. All rights reserved.

import UIKit

@objc protocol KNWalletHeaderViewDelegate: class {
  func walletHeaderScanQRCodePressed(wallet: KNWalletObject, sender: KNWalletHeaderView)
  func walletHeaderWalletListPressed(wallet: KNWalletObject, sender: KNWalletHeaderView)
  @objc optional func walletHeaderDebugButtonPressed(sender: KNWalletHeaderView)
}

struct KNWalletHeaderViewModel {
  init() {}

  var backgroundColor: UIColor {
    return UIColor.Kyber.navDark
  }

  var tintColor: UIColor {
    return UIColor.white
  }

  var barcodeIcon: String {
    return "barcode_white"
  }

  var walletListIcon: String {
    return"burger_menu"
  }

  var walletAddressAttributes: [NSAttributedStringKey: Any] {
    return [NSAttributedStringKey.foregroundColor: UIColor.Kyber.lightGray,
            NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 16)!,
            NSAttributedStringKey.kern: 0.0,
    ]
  }

  var walletNameAttributes: [NSAttributedStringKey: Any] {
    return [NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont(name: "SFProText-Medium", size: 16)!,
            NSAttributedStringKey.kern: 0.0,
    ]
  }
}

class KNWalletHeaderView: XibLoaderView {
  @IBOutlet var containerView: UIView!
  @IBOutlet weak var walletIconImageView: UIImageView!
  @IBOutlet weak var walletInfoLabel: UILabel!
  @IBOutlet weak var debugButton: UIButton!
  @IBOutlet weak var walletListButton: UIButton!

  @IBOutlet weak var pendingTxNotiView: UIView!

  weak var delegate: KNWalletHeaderViewDelegate?
  fileprivate var viewModel = KNWalletHeaderViewModel()

  fileprivate var wallet: KNWalletObject?

  override func commonInit() {
    super.commonInit()
    self.walletInfoLabel.text = ""
    self.pendingTxNotiView.rounded(radius: self.pendingTxNotiView.frame.width / 2.0)
    self.pendingTxNotiView.isHidden = true
    self.updateUI()
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
    self.walletListButton.setImage(UIImage(named: self.viewModel.walletListIcon), for: .normal)

    // Allow tap to open QR code view
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.shouldOpenQRCode(_:)))
    self.walletInfoLabel.addGestureRecognizer(tapGesture)
    self.walletInfoLabel.isUserInteractionEnabled = true

    self.debugButton.setTitleColor(self.viewModel.tintColor, for: .normal)
    self.debugButton.isHidden = true
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

  @IBAction func walletListButtonPressed(_ sender: Any) {
    guard let wallet = self.wallet else { return }
    self.delegate?.walletHeaderWalletListPressed(wallet: wallet, sender: self)
  }

  @objc func shouldOpenQRCode(_ sender: Any?) {
    guard let wallet = self.wallet else { return }
    self.delegate?.walletHeaderScanQRCodePressed(wallet: wallet, sender: self)
  }

  @IBAction func debugButtonPressed(_ sender: Any) {
    self.delegate?.walletHeaderDebugButtonPressed?(sender: self)
  }
}
