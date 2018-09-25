// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length

import UIKit
import Moya
import Result
import QRCodeReaderViewController
import TrustCore

enum KYCPersonalInfoViewEvent {
  case next(firstName: String, lastName: String, gender: String, dob: String, nationality: String, country: String, wallets: [(String, String)])
}

class KYCPersonalInfoViewModel {

  let user: IEOUser
  let nationalities: [String]
  let countries: [String]

  fileprivate(set) var gender: String = ""
  fileprivate(set) var dob: String = ""

  fileprivate(set) var wallets: [(String, String)] = []
  fileprivate(set) var hasModifiedWallets: Bool = false

  init(user: IEOUser) {
    self.user = user
    self.wallets = []
    let json = KNJSONLoaderUtil.jsonDataFromFile(with: "kyc_data") ?? [:]
    self.nationalities = json["nationalities"] as? [String] ?? []
    self.countries = json["countries"] as? [String] ?? []
  }

  func updateGender(_ gender: String) { self.gender = gender }
  func updateDoB(_ dob: String) { self.dob = dob }
  func removeAddress(at id: Int) {
    self.wallets.remove(at: id)
    self.hasModifiedWallets = true
  }

  func updateWallets(_ wallets: [(String, String)]) {
    self.wallets = wallets
  }

  @discardableResult
  func addAddress(_ address: String, label: String) -> Bool {
    guard self.wallets.first(where: { $0.1 == address }) == nil else { return false }
    self.wallets.append((label, address))
    self.hasModifiedWallets = true
    return true
  }

  func getUserWallets(completion: @escaping (Result<[(String, String)], AnyError>) -> Void) {
    let provider = MoyaProvider<ProfileKYCService>()
    provider.request(.userWallets(accessToken: self.user.accessToken)) { result in
      switch result {
      case .success(let resp):
        do {
          _ = try resp.filterSuccessfulStatusCodes()
          let json: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let dataArr = json["data"] as? [JSONDictionary] ?? []
          let values = dataArr.map({ ($0["label"] as? String ?? "", $0["address"] as? String ?? "") })
          if !self.hasModifiedWallets {
            self.wallets = values
          }
          completion(.success(values))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }

  func checkWalletExist(wallet: String, completion: @escaping (Result<Bool, AnyError>) -> Void) {
    guard self.wallets.first(where: { $0.1.lowercased() == wallet.lowercased() }) == nil else {
      completion(.success(true))
      return
    }
    let provider = MoyaProvider<ProfileKYCService>()
    provider.request(.checkWalletExist(accessToken: user.accessToken, wallet: wallet)) { result in
      switch result {
      case .success(let resp):
        do {
          _ = try resp.filterSuccessfulStatusCodes()
          let json: JSONDictionary = try resp.mapJSON(failsOnEmptyData: false) as? JSONDictionary ?? [:]
          let existed: Bool = json["wallet_existed"] as? Bool ?? false
          completion(.success(existed))
        } catch let error {
          completion(.failure(AnyError(error)))
        }
      case .failure(let error):
        completion(.failure(AnyError(error)))
      }
    }
  }
}

protocol KYCPersonalInfoViewControllerDelegate: class {
  func kycPersonalInfoViewController(_ controller: KYCPersonalInfoViewController, run event: KYCPersonalInfoViewEvent)
}

class KYCPersonalInfoViewController: KNBaseViewController {

  let kWalletTableViewCellID = "kWalletTableViewCellID"
  let kWalletCellRowHeight: CGFloat = 84.0

  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var firstNameTextField: UITextField!
  @IBOutlet weak var lastNameTextField: UITextField!
  @IBOutlet weak var maleButton: UIButton!
  @IBOutlet weak var femaleButton: UIButton!
  @IBOutlet weak var dateOfBirthTextField: UITextField!
  @IBOutlet weak var nationalityTextField: UITextField!
  @IBOutlet weak var countryOfResidenceTextField: UITextField!

  @IBOutlet weak var walletsDataView: UIView!
  @IBOutlet weak var walletsTableView: UITableView!
  @IBOutlet weak var noWalletsTextLabel: UILabel!
  @IBOutlet weak var heightConstraintWalletsDataView: NSLayoutConstraint!
  @IBOutlet weak var addWalletContainerView: UIView!
  @IBOutlet weak var heightConstraintForAddWalletView: NSLayoutConstraint!
  @IBOutlet weak var addWalletButton: UIButton!
  @IBOutlet weak var walletLabelTextField: UITextField!
  @IBOutlet weak var walletAddressTextField: UITextField!

  @IBOutlet weak var nextButton: UIButton!

  fileprivate var fakeTextField: UITextField = UITextField(frame: CGRect.zero)
  fileprivate var currentValue: String = ""
  fileprivate var isSelectNationality: Bool = false

  lazy var datePicker: UIDatePicker = {
    let frame = CGRect(
      x: 0,
      y: self.view.frame.height - 200.0,
      width: self.view.frame.width,
      height: 200.0
    )
    let picker = UIDatePicker(frame: frame)
    picker.datePickerMode = .date
    picker.minimumDate = Date().addingTimeInterval(-100.0 * 360.0 * 24.0 * 60.0 * 60.0)
    picker.maximumDate = Date()
    picker.addTarget(self, action: #selector(self.dateOfBirthDidChange(_:)), for: .valueChanged)
    picker.date = Date()
    return picker
  }()

  lazy var nationalityPickerView: UIPickerView = {
    let pickerView = UIPickerView(frame: CGRect.zero)
    pickerView.showsSelectionIndicator = true
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()

  lazy var countryPickerView: UIPickerView = {
    let pickerView = UIPickerView(frame: CGRect.zero)
    pickerView.showsSelectionIndicator = true
    pickerView.dataSource = self
    pickerView.delegate = self
    return pickerView
  }()

  lazy var toolBar: UIToolbar = {
    let frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
    let toolBar = UIToolbar(frame: frame)
    toolBar.barStyle = .default
    let doneBtn = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(self.countryPickerDonePressed(_:))
    )
    let flexibleSpaceBtn = UIBarButtonItem(
      barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
      target: nil,
      action: nil
    )
    doneBtn.tintColor = UIColor.Kyber.dark
    let cancelBtn = UIBarButtonItem(
      barButtonSystemItem: .cancel,
      target: self,
      action: #selector(self.countryPickerCancelPressed(_:))
    )
    cancelBtn.tintColor = UIColor.Kyber.dark
    toolBar.setItems([cancelBtn, flexibleSpaceBtn, doneBtn], animated: false)
    return toolBar
  }()

  weak var delegate: KYCPersonalInfoViewControllerDelegate?
  fileprivate var viewModel: KYCPersonalInfoViewModel

  init(viewModel: KYCPersonalInfoViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KYCPersonalInfoViewController.className, bundle: nil)
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
    self.viewModel.getUserWallets { _ in
      self.updateWalletsData()
    }
  }

  fileprivate func setupUI() {
    self.setupDataContent()
    self.setupWalletsDataView()
  }

  fileprivate func setupDataContent() {
    self.maleButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.maleButton.frame.height / 2.0
    )
    self.femaleButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.femaleButton.frame.height / 2.0
    )

    self.dateOfBirthTextField.inputView = self.datePicker
    self.dateOfBirthTextField.delegate = self
    self.view.addSubview(self.fakeTextField)
  }

  fileprivate func setupWalletsDataView() {
    self.addWalletButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: 4.0
    )
    self.noWalletsTextLabel.text = "You haven't added any wallets yet.".toBeLocalised()

    self.walletsTableView.register(UITableViewCell.self, forCellReuseIdentifier: kWalletTableViewCellID)
    self.walletsTableView.rowHeight = kWalletCellRowHeight
    self.walletsTableView.delegate = self
    self.walletsTableView.dataSource = self
    self.updateWalletsData()

    self.nextButton.setTitle("Next".toBeLocalised(), for: .normal)
    self.nextButton.rounded(radius: 4.0)
  }

  @IBAction func maleButtonPressed(_ sender: Any) {
    self.viewModel.updateGender(self.viewModel.gender == "Male" ? "" : "Male")
    self.updateGenderUI()
  }

  @IBAction func femaleButtonPressed(_ sender: Any) {
    self.viewModel.updateGender(self.viewModel.gender == "Female" ? "" : "Female")
    self.updateGenderUI()
  }

  fileprivate func updateGenderUI() {
    self.maleButton.rounded(
      color: self.viewModel.gender == "Male" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.gender == "Male" ? 6.0 : 1.0,
      radius: self.maleButton.frame.height / 2.0
    )
    self.femaleButton.rounded(
      color: self.viewModel.gender == "Female" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.gender == "Female" ? 6.0 : 1.0,
      radius: self.maleButton.frame.height / 2.0
    )
  }

  @IBAction func nationalityButtonPressed(_ sender: Any) {
    self.isSelectNationality = true
    self.fakeTextField.inputView = self.countryPickerView

    self.fakeTextField.inputAccessoryView = self.toolBar
    self.currentValue = self.nationalityTextField.text ?? ""
    if let id = self.viewModel.nationalities.index(of: self.currentValue) {
      self.currentValue = self.viewModel.nationalities[id]
    } else {
      self.currentValue = self.viewModel.nationalities[0]
    }

    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func countryOfResidenceButtonPressed(_ sender: Any) {
    self.isSelectNationality = false
    self.fakeTextField.inputView = self.countryPickerView

    self.fakeTextField.inputAccessoryView = self.toolBar
    self.currentValue = self.countryOfResidenceTextField.text ?? ""
    if let id = self.viewModel.countries.index(of: self.currentValue) {
      self.currentValue = self.viewModel.countries[id]
    } else {
      self.currentValue = self.viewModel.countries[0]
    }

    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func addWalletButtonPressed(_ sender: Any) {
    guard let label = self.walletLabelTextField.text, !label.isEmpty else {
      self.showWarningTopBannerMessage(
        with: "Invalid input".toBeLocalised(),
        message: "Please enter a valid wallet label".toBeLocalised(),
        time: 1.5
      )
      return
    }
    guard let address = self.walletAddressTextField.text, Address(string: address) != nil else {
      self.showWarningTopBannerMessage(
        with: "Invalid input".toBeLocalised(),
        message: "Please enter a valid address".toBeLocalised(),
        time: 1.5
      )
      return
    }
    self.displayLoading(text: "Checking...", animated: true)
    self.viewModel.checkWalletExist(wallet: address) { [weak self] result in
      guard let `self` = self else { return }
      self.hideLoading()
      switch result {
      case .success(let ok):
        if !ok {
          self.viewModel.addAddress(address, label: label)
          self.updateWalletsData()
        } else {
          self.showWarningTopBannerMessage(
            with: "Address existed".toBeLocalised(),
            message: "Your address has already added.".toBeLocalised(),
            time: 1.5
          )
        }
      case .failure(let error):
        self.displayError(error: error)
      }
    }
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    // Check first + last name
    let firstName = self.firstNameTextField.text ?? ""
    let lastName = self.lastNameTextField.text ?? ""
    guard !firstName.isEmpty && !lastName.isEmpty else {
      self.showWarningTopBannerMessage(
        with: "Invalid name".toBeLocalised(),
        message: "Please enter a valid name".toBeLocalised(),
        time: 1.5
      )
      return
    }
    // Check gender selected
    guard !self.viewModel.gender.isEmpty else {
      self.showWarningTopBannerMessage(
        with: "Invalid gender".toBeLocalised(),
        message: "Please select your gender to continue".toBeLocalised(),
        time: 1.5
      )
      return
    }
    // Check date of birth
    guard !self.viewModel.dob.isEmpty else {
      self.showWarningTopBannerMessage(
        with: "Invalid date of birth".toBeLocalised(),
        message: "Please select your date of birth to continue".toBeLocalised(),
        time: 1.5
      )
      return
    }
    // Check nationality
    let nationality = self.nationalityTextField.text ?? ""
    guard self.viewModel.nationalities.contains(nationality) else {
      self.showWarningTopBannerMessage(
        with: "Invalid nationality".toBeLocalised(),
        message: "Please enter/select a valid nationality to continue".toBeLocalised(),
        time: 1.5
      )
      return
    }
    // Check country of residences
    let country = self.countryOfResidenceTextField.text ?? ""
    guard self.viewModel.countries.contains(country) else {
      self.showWarningTopBannerMessage(
        with: "Invalid country".toBeLocalised(),
        message: "Please enter/select a valid country to continue".toBeLocalised(),
        time: 1.5
      )
      return
    }
    let nextEvent = KYCPersonalInfoViewEvent.next(
      firstName: firstName,
      lastName: lastName,
      gender: self.viewModel.gender,
      dob: self.viewModel.dob,
      nationality: nationality,
      country: country,
      wallets: self.viewModel.wallets
    )
    self.delegate?.kycPersonalInfoViewController(self, run: nextEvent)
  }

  @objc func dateOfBirthDidChange(_ sender: Any) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dob = dateFormatter.string(from: self.datePicker.date)
    self.dateOfBirthTextField.text = dob
    self.viewModel.updateDoB(dob)
  }

  @objc func countryPickerDonePressed(_ sender: Any) {
    self.fakeTextField.resignFirstResponder()
    if self.isSelectNationality {
      self.nationalityTextField.text = self.currentValue
    } else {
      self.countryOfResidenceTextField.text = self.currentValue
    }
  }

  @objc func countryPickerCancelPressed(_ sender: Any) {
    self.fakeTextField.resignFirstResponder()
  }

  fileprivate func updateWalletsData() {
    if self.viewModel.wallets.isEmpty {
      self.noWalletsTextLabel.isHidden = false
      self.walletsTableView.isHidden = true
      self.heightConstraintWalletsDataView.constant = 260.0
      self.heightConstraintForAddWalletView.constant = 200.0
      self.addWalletContainerView.isHidden = false
    } else {
      // Only allow add up to 3 wallets
      let hasAddWallet: Bool = self.viewModel.wallets.count < 3
      let addWalletHeight: CGFloat = hasAddWallet ? 200.0 : 0.0
      self.heightConstraintWalletsDataView.constant = CGFloat(self.viewModel.wallets.count) * kWalletCellRowHeight + addWalletHeight
      self.addWalletContainerView.isHidden = !hasAddWallet
      self.heightConstraintForAddWalletView.constant = addWalletHeight
      self.noWalletsTextLabel.isHidden = true
      self.walletsTableView.isHidden = false
      self.walletsTableView.reloadData()
    }
  }

  func updatePersonalInfoView(with details: IEOUserKYCDetails) {
    let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter
    }()
    guard !details.firstName.isEmpty else { return }
    self.firstNameTextField.text = details.firstName
    self.lastNameTextField.text = details.lastName
    self.viewModel.updateGender(details.gender ? "Male": "Female")
    self.updateGenderUI()
    self.viewModel.updateDoB(details.dob)
    if let dob = dateFormatter.date(from: details.dob) {
      self.dateOfBirthTextField.text = details.dob
      self.datePicker.setDate(dob, animated: false)
    }
    if let nationalID = self.viewModel.nationalities.index(of: details.nationality) {
      self.nationalityTextField.text = details.nationality
      self.nationalityPickerView.selectRow(nationalID, inComponent: 0, animated: false)
    }
    if let countryID = self.viewModel.countries.index(of: details.country) {
      self.countryOfResidenceTextField.text = details.country
      self.countryPickerView.selectRow(countryID, inComponent: 0, animated: false)
    }
    self.view.layoutIfNeeded()
  }
}

extension KYCPersonalInfoViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

extension KYCPersonalInfoViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.wallets.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Remove") { (_, _) in
      self.removeAddress(at: indexPath)
    }
    deleteAction.backgroundColor = UIColor.Kyber.fire
    return [deleteAction]
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath)
    cell.textLabel?.isUserInteractionEnabled = false
    let wallets = self.viewModel.wallets
    cell.tintColor = UIColor.Kyber.shamrock
    let wallet = wallets[indexPath.row]
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

  fileprivate func removeAddress(at indexPath: IndexPath) {
    self.viewModel.removeAddress(at: indexPath.row)
    self.walletsTableView.deleteRows(at: [indexPath], with: .automatic)
    self.updateWalletsData()
  }
}

extension KYCPersonalInfoViewController: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    if self.isSelectNationality {
      self.currentValue = self.viewModel.nationalities[row]
    } else {
      self.currentValue = self.viewModel.countries[row]
    }
  }
}

extension KYCPersonalInfoViewController: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if self.isSelectNationality {
      return self.viewModel.nationalities.count
    }
    return self.viewModel.countries.count
  }

  func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
    return 32
  }

  func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
    let attributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor.Kyber.dark,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 14),
    ]
    let string: String = {
      if self.isSelectNationality {
        return self.viewModel.nationalities[row]
      }
      return self.viewModel.countries[row]
    }()
    return NSAttributedString(
      string: string,
      attributes: attributes
    )
  }
}

extension KYCPersonalInfoViewController: UITextFieldDelegate {
  func textFieldDidBeginEditing(_ textField: UITextField) {
    if textField == self.dateOfBirthTextField {
      self.dateOfBirthDidChange(textField)
    }
  }
}

extension KYCPersonalInfoViewController: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      self.walletAddressTextField.text = result
    }
  }
}
