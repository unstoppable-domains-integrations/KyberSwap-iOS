// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import QRCodeReaderViewController
import TrustCore

enum KNProfileHomeViewEvent {
  case signIn
  case signUp
  case logOut
  case openVerification
}

protocol KNProfileHomeViewControllerDelegate: class {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNProfileHomeViewEvent)
}

class KNProfileHomeViewController: KNBaseViewController {

  let kWalletTableViewCellID: String = "kWalletTableViewCellID"
  let kWalletCellRowHeight: CGFloat = 84.0

  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var notSignInView: UIView!
  @IBOutlet weak var notSignInTitleLabel: UILabel!
  @IBOutlet weak var notSignInDescLabel: UILabel!
  @IBOutlet weak var signUpButton: UIButton!
  @IBOutlet weak var signInButton: UIButton!

  @IBOutlet weak var myProfileTextLabel: UILabel!
  @IBOutlet weak var myWalletsTextLabel: UILabel!
  @IBOutlet weak var signedInView: UIView!
  @IBOutlet weak var logOutButton: UIButton!
  @IBOutlet weak var userImageView: UIImageView!
  @IBOutlet weak var userNameLabel: UILabel!
  @IBOutlet weak var userEmailLabel: UILabel!
  @IBOutlet weak var userKYCStatusLabel: UILabel!

  @IBOutlet weak var userKYCStatusContainerView: UIView!
  @IBOutlet weak var userKYCStatusDescLabel: UILabel!
  @IBOutlet weak var userKYCActionButton: UIButton!
  @IBOutlet weak var heightConstraintUserKYCStatusView: NSLayoutConstraint!

  @IBOutlet weak var noWalletTextLabel: UILabel!
  @IBOutlet weak var walletsTableView: UITableView!
  @IBOutlet weak var maximumWalletsTextLabel: UILabel!
  @IBOutlet weak var heightConstraintWalletsTableView: NSLayoutConstraint!
  @IBOutlet weak var addWalletContainer: UIView!
  @IBOutlet weak var heightConstraintForAddWalletContainer: NSLayoutConstraint!
  @IBOutlet weak var addWalletLabelTextField: UITextField!
  @IBOutlet weak var addWalletAddressTextField: UITextField!
  @IBOutlet weak var addWalletAddButton: UIButton!
  @IBOutlet weak var bottomPaddingConstraintForSignedInView: NSLayoutConstraint!

  weak var delegate: KNProfileHomeViewControllerDelegate?
  fileprivate var viewModel: KNProfileHomeViewModel

  fileprivate var walletTimer: Timer?

  fileprivate let appStyle = KNAppStyleType.current

  init(viewModel: KNProfileHomeViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNProfileHomeViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.fetchWalletList()
    self.walletTimer?.invalidate()
    self.walletTimer = Timer.scheduledTimer(
      withTimeInterval: KNEnvironment.default == .production ? 60.0 : 10.0,
      repeats: true,
      block: { [weak self] _ in
      self?.fetchWalletList()
      }
    )
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.walletTimer?.invalidate()
  }

  fileprivate func setupUI() {
    self.navTitleLabel.text = NSLocalizedString("profile", value: "Profile", comment: "")
    self.setupNotSignInView()
    self.setupUserSignedInView()
  }

  fileprivate func setupNotSignInView() {
    self.signInButton.rounded(
      radius: self.appStyle.buttonRadius(for: self.signUpButton.frame.height)
    )
    self.notSignInTitleLabel.text = NSLocalizedString(
      "profile", value: "Profile",
      comment: ""
    )
    self.notSignInDescLabel.text = NSLocalizedString(
      "welcome.third.screen.description", value: "Profile process just got simpler. Straight from the app.",
      comment: ""
    )
    self.signInButton.setTitle(
      NSLocalizedString("sign.in", value: "Sign In", comment: ""),
      for: .normal
    )
    self.signUpButton.rounded(
      radius: self.appStyle.buttonRadius(for: self.signUpButton.frame.height)
    )
    self.signUpButton.setTitle(
      NSLocalizedString("sign.up", value: "Sign Up", comment: ""),
      for: .normal
    )
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
  }

  fileprivate func setupUserSignedInView() {
    self.bottomPaddingConstraintForSignedInView.constant = self.bottomPaddingSafeArea()
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
    self.myProfileTextLabel.text = NSLocalizedString("my.profile", value: "My Profile", comment: "")
    self.myWalletsTextLabel.text = NSLocalizedString("my.wallets", value: "My Wallet(s)", comment: "")
    self.logOutButton.setTitle(NSLocalizedString("log.out", value: "Log Out", comment: ""), for: .normal)
    let descText: String = NSLocalizedString(
      "complete.your.profile.verfication.increase.trade.limits",
      value: "Complete Your Profile Verification\nIncrease KyberSwap's trade limits",
      comment: ""
    )
    self.updateKYCStatusDescLabel(with: descText)

    self.userImageView.rounded(
      color: UIColor.Kyber.border,
      width: 0.5,
      radius: self.userImageView.frame.height / 2.0
    )

    self.userKYCActionButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    self.userKYCStatusLabel.rounded(radius: 2.0)

    self.noWalletTextLabel.text = NSLocalizedString("you.have.not.added.any.wallets.yet", value: "You haven't added any wallets yet.", comment: "")
    self.maximumWalletsTextLabel.text = NSLocalizedString("maximum.three.wallets", value: "Maximum 3 wallets", comment: "")
    self.walletsTableView.register(UITableViewCell.self, forCellReuseIdentifier: kWalletTableViewCellID)
    self.walletsTableView.rowHeight = kWalletCellRowHeight
    self.walletsTableView.delegate = self
    self.walletsTableView.dataSource = self

    self.addWalletLabelTextField.placeholder = NSLocalizedString("label", value: "Label", comment: "")
    self.addWalletAddressTextField.placeholder = NSLocalizedString("address", value: "Address", comment: "")
    self.addWalletAddButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    self.addWalletAddButton.setTitle(
      NSLocalizedString("add", value: "Add", comment: ""),
      for: .normal
    )
    self.updateUIUserDidSignedIn()
  }

  fileprivate func updateKYCStatusDescLabel(with string: String) {
    self.userKYCStatusDescLabel.attributedText = {
      let attributedString = NSMutableAttributedString()
      attributedString.append(NSAttributedString(string: string))
      let index = string.firstIndex(of: "\n")!
      let attributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
        ]
      let range = NSRange(location: 0, length: index.encodedOffset)
      attributedString.addAttributes(attributes, range: range)
      return attributedString
    }()
    self.view.layoutIfNeeded()
  }

  fileprivate func fetchWalletList() {
    self.viewModel.getUserWallets { _ in
      self.updateWalletsData()
    }
  }

  fileprivate func updateUIUserDidSignedIn() {
    guard let user = self.viewModel.currentUser else { return }
    let url: String = {
      if user.avatarURL.starts(with: "http") { return user.avatarURL }
      return "\(KNAppTracker.getKyberProfileBaseString())\(user.avatarURL)"
    }()
    self.userImageView.setImage(
      with: url,
      placeholder: UIImage(named: "account"),
      size: nil
    )
    self.userNameLabel.text = user.name
    self.userEmailLabel.text = user.contactID
    let status: String = {
      switch user.kycStatus.lowercased() {
      case "draft", "none": return "Unverified"
      case "pending": return "Pending"
      case "approved": return "Approved"
      case "rejected": return "Rejected"
      default: return "Unknown"
      }
    }()
    self.userKYCStatusLabel.text = "\(NSLocalizedString(status.lowercased(), value: status, comment: ""))  "

    let actionTitle: String = status == "Rejected" ? NSLocalizedString("resubmit", value: "Re-submit", comment: "") : NSLocalizedString("verify", value: "Verify", comment: "")
    self.userKYCActionButton.setTitle(actionTitle, for: .normal)

    if status == "Approved" {
      self.userKYCStatusLabel.backgroundColor = UIColor.Kyber.shamrock
    } else if status == "Pending" {
      self.userKYCStatusLabel.backgroundColor = UIColor.Kyber.merigold
    } else if status == "Rejected" {
      self.userKYCStatusLabel.backgroundColor = UIColor.Kyber.strawberry
    } else {
      self.userKYCStatusLabel.backgroundColor = UIColor(red: 154, green: 171, blue: 180)
    }
    let descText: String = {
      if status == "Rejected" {
        let reason = user.kycDetails?.rejectedReason ?? ""
        return "\(NSLocalizedString("profile.is.rejected", value: "Your Profile is rejected", comment: ""))\n\(reason)"
      }
      return NSLocalizedString(
        "complete.your.profile.verfication.increase.trade.limits",
        value: "Complete Your Profile Verification\nIncrease KyberSwap's trade limits",
        comment: ""
      )
    }()
    self.updateKYCStatusDescLabel(with: descText)

    if status == "Approved" || status == "Pending" {
      self.heightConstraintUserKYCStatusView.constant = 0.0
      self.userKYCStatusContainerView.isHidden = true
    } else {
      self.userKYCStatusContainerView.isHidden = false
      self.heightConstraintUserKYCStatusView.constant = 160.0
    }
    self.updateWalletsData()
  }

  fileprivate func updateWalletsData() {
    if self.viewModel.wallets.isEmpty {
      self.noWalletTextLabel.isHidden = false
      self.walletsTableView.isHidden = true
      self.heightConstraintWalletsTableView.constant = 260.0
      self.addWalletContainer.isHidden = false
      self.heightConstraintForAddWalletContainer.constant = 200.0
    } else {
      let hasAddWalletView: Bool = self.viewModel.wallets.count < 3
      let addWalletViewHeight: CGFloat = hasAddWalletView ? 200.0 : 0.0
      self.heightConstraintWalletsTableView.constant = CGFloat(self.viewModel.wallets.count) * kWalletCellRowHeight + addWalletViewHeight
      self.noWalletTextLabel.isHidden = true
      self.walletsTableView.isHidden = false
      self.addWalletContainer.isHidden = !hasAddWalletView
      self.heightConstraintForAddWalletContainer.constant = addWalletViewHeight
      self.walletsTableView.reloadData()
    }
    self.view.layoutIfNeeded()
  }

  @IBAction func signInButtonPressed(_ sender: Any) {
    self.delegate?.profileHomeViewController(self, run: .signIn)
  }

  @IBAction func signUpButtonPressed(_ sender: Any) {
    self.delegate?.profileHomeViewController(self, run: .signUp)
  }

  @IBAction func logOutButtonPressed(_ sender: Any) {
    self.delegate?.profileHomeViewController(self, run: .logOut)
  }

  @IBAction func userKYCActionButtonPressed(_ sender: Any) {
    self.delegate?.profileHomeViewController(self, run: .openVerification)
  }

  @IBAction func addWalletScanQRCodePressed(_ sender: Any) {
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func addWalletAddButtonPressed(_ sender: Any) {
    guard let label = self.addWalletLabelTextField.text, !label.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.wallet.label", value: "Please enter a valid wallet label", comment: ""),
        time: 1.5
      )
      return
    }
    guard let address = self.addWalletAddressTextField.text, Address(string: address) != nil else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.address", value: "Please enter a valid address", comment: ""),
        time: 1.5
      )
      return
    }
    self.displayLoading(text: "\(NSLocalizedString("adding", value: "Invalid Adding", comment: ""))...", animated: true)
    self.viewModel.addWallet(label: label, address: address) { [weak self] result in
      guard let `self` = self else { return }
      self.hideLoading()
      switch result {
      case .success(let resp):
        let isAdded: Bool = resp.0
        let message: String = resp.1
        if isAdded {
          self.showSuccessTopBannerMessage(
            with: NSLocalizedString("success", value: "Success", comment: ""),
            message: NSLocalizedString("your.wallet.has.been.added.successfully", value: "Your wallet has been added successfully!", comment: ""),
            time: 1.5
          )
          self.fetchWalletList()
        } else {
          self.showErrorTopBannerMessage(
            with: NSLocalizedString("failed", value: "Failed", comment: ""),
            message: message,
            time: 1.5
          )
        }
      case .failure(let error):
        self.displayError(error: error)
      }
    }
  }
}

extension KNProfileHomeViewController {
  func coordinatorUserDidSignInSuccessfully() {
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
    self.updateUIUserDidSignedIn()
  }

  func coordinatorDidSignOut() {
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
  }
}

extension KNProfileHomeViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

extension KNProfileHomeViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.wallets.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath)
    cell.textLabel?.isUserInteractionEnabled = false
    cell.tintColor = UIColor.Kyber.shamrock
    let wallet = self.viewModel.wallets[indexPath.row]
    cell.textLabel?.attributedText = {
      let attributedString = NSMutableAttributedString()
      let nameAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
        NSAttributedStringKey.foregroundColor: UIColor.Kyber.mirage,
        NSAttributedStringKey.kern: 1.0,
      ]
      let addressAttributes: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
        NSAttributedStringKey.foregroundColor: UIColor.Kyber.grayChateau,
        NSAttributedStringKey.kern: 1.0,
      ]
      attributedString.append(NSAttributedString(string: "    \(wallet.0)", attributes: nameAttributes))
      let addressString: String = "      \(wallet.1.prefix(8))...\(wallet.1.suffix(6))"
      attributedString.append(NSAttributedString(string: "\n\(addressString)", attributes: addressAttributes))
      return attributedString
    }()
    cell.textLabel?.numberOfLines = 2
    cell.backgroundColor = {
      return indexPath.row % 2 == 0 ? UIColor(red: 242, green: 243, blue: 246) : UIColor.Kyber.whisper
    }()
    return cell
  }
}

extension KNProfileHomeViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.addWalletAddressTextField.text = result
    }
  }
}
