// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KNProfileHomeViewEvent {
  case signIn
  case signUp
  case logOut
  case openVerification
  case addWallet
}

protocol KNProfileHomeViewControllerDelegate: class {
  func profileHomeViewController(_ controller: KNProfileHomeViewController, run event: KNProfileHomeViewEvent)
}

class KNProfileHomeViewController: KNBaseViewController {

  let kWalletTableViewCellID: String = "kWalletTableViewCellID"
  let kWalletCellRowHeight: CGFloat = 84.0

  @IBOutlet weak var notSignInView: UIView!
  @IBOutlet weak var notSignInTitleLabel: UILabel!
  @IBOutlet weak var notSignInDescLabel: UILabel!
  @IBOutlet weak var signUpButton: UIButton!
  @IBOutlet weak var signInButton: UIButton!

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
  @IBOutlet weak var heightConstraintWalletsTableView: NSLayoutConstraint!

  weak var delegate: KNProfileHomeViewControllerDelegate?
  fileprivate var viewModel: KNProfileHomeViewModel

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

  fileprivate func setupUI() {
    self.setupNotSignInView()
    self.setupUserSignedInView()
  }

  fileprivate func setupNotSignInView() {
    self.signInButton.rounded(
      radius: self.appStyle.buttonRadius(for: self.signUpButton.frame.height)
    )
    self.signInButton.setTitle(
      self.appStyle.buttonTitle(with: "Sign In".toBeLocalised()),
      for: .normal
    )
    self.signUpButton.rounded(
      radius: self.appStyle.buttonRadius(for: self.signUpButton.frame.height)
    )
    self.signUpButton.setTitle(
      self.appStyle.buttonTitle(with: "Sign Up".toBeLocalised()),
      for: .normal
    )
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
  }

  fileprivate func setupUserSignedInView() {
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
    self.logOutButton.setTitle("Log Out".toBeLocalised(), for: .normal)

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

    self.noWalletTextLabel.text = "You haven't added any wallets yet.".toBeLocalised()

    self.walletsTableView.register(UITableViewCell.self, forCellReuseIdentifier: kWalletTableViewCellID)
    self.walletsTableView.rowHeight = kWalletCellRowHeight
    self.walletsTableView.delegate = self
    self.walletsTableView.dataSource = self

    self.updateUIUserDidSignedIn()
  }

  fileprivate func updateUIUserDidSignedIn() {
    guard let user = self.viewModel.currentUser else { return }
    self.userNameLabel.text = user.name
    self.userEmailLabel.text = user.contactID
    self.userKYCStatusLabel.text = "\(user.kycStatus)  "

    if user.kycStatus.lowercased() == "approved" {
      self.userKYCStatusLabel.backgroundColor = UIColor.Kyber.shamrock
      self.heightConstraintUserKYCStatusView.constant = 0.0
      self.userKYCStatusContainerView.isHidden = true
    } else {
      self.userKYCStatusLabel.backgroundColor = UIColor(red: 154, green: 171, blue: 180)
      self.userKYCStatusContainerView.isHidden = false
      self.heightConstraintUserKYCStatusView.constant = 160.0
    }

    if user.registeredAddress.isEmpty {
      self.noWalletTextLabel.isHidden = false
      self.walletsTableView.isHidden = true
      self.heightConstraintWalletsTableView.constant = 60.0
    } else {
      self.heightConstraintWalletsTableView.constant = CGFloat(user.registeredAddress.count) * kWalletCellRowHeight
      self.noWalletTextLabel.isHidden = true
      self.walletsTableView.isHidden = false
    }
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

  @IBAction func addWalletsButtonPressed(_ sender: Any) {
    self.delegate?.profileHomeViewController(self, run: .addWallet)
  }
}

extension KNProfileHomeViewController {
  func coordinatorUserDidSignInSuccessfully() {
    self.notSignInView.isHidden = self.viewModel.isUserSignedIn
    self.signedInView.isHidden = !self.viewModel.isUserSignedIn
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
    return self.viewModel.currentUser?.registeredAddress.count ?? 0
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath)
    cell.textLabel?.isUserInteractionEnabled = false
    guard let addresses = self.viewModel.currentUser?.registeredAddress else { return cell }
    cell.tintColor = UIColor.Kyber.shamrock
    let address = addresses[indexPath.row]
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
      attributedString.append(NSAttributedString(string: "    Untitled", attributes: nameAttributes))
      let addressString: String = "         \(address.prefix(8))...\(address.suffix(6))"
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
