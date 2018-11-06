// Copyright SIX DAY LLC. All rights reserved.

//swiftlint:disable file_length

import UIKit
import Moya
import Result
import QRCodeReaderViewController
import TrustCore
import Photos
import MobileCoreServices
import AVFoundation

enum KYCPersonalInfoViewEvent {
  case next(firstName: String, lastName: String, gender: String, dob: String, nationality: String, country: String, wallets: [(String, String)])
}

class KYCPersonalInfoViewModel {

  let user: IEOUser
  let nationalities: [String]
  let countries: [String]
  let proofOfAddressTypes: [String]
  let sourceFunds: [String]

  lazy var occupationCodes: [String: String] = {
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: "kyc_occupation_code") else { return [:] }
    let data = json["data"] as? [String: String] ?? [:]
    return data
  }()

  lazy var industryCodes: [String: String] = {
    guard let json = KNJSONLoaderUtil.jsonDataFromFile(with: "kyc_industry_code") else { return [:] }
    let data = json["data"] as? [String: String] ?? [:]
    return data
  }()

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
    self.proofOfAddressTypes = json["proof_address"] as? [String] ?? []
    self.sourceFunds = json["source_funds"] as? [String] ?? []
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
  @IBOutlet weak var genderTextLabel: UILabel!
  @IBOutlet weak var maleTextLabel: UILabel!
  @IBOutlet weak var femaleTextLabel: UILabel!

  @IBOutlet weak var mywalletsLabel: UILabel!
  @IBOutlet weak var maximumWalletsLabel: UILabel!
  @IBOutlet weak var walletsDataView: UIView!
  @IBOutlet weak var walletsTableView: UITableView!
  @IBOutlet weak var noWalletsTextLabel: UILabel!
  @IBOutlet weak var heightConstraintWalletsDataView: NSLayoutConstraint!
  @IBOutlet weak var addWalletContainerView: UIView!
  @IBOutlet weak var heightConstraintForAddWalletView: NSLayoutConstraint!
  @IBOutlet weak var addWalletButton: UIButton!
  @IBOutlet weak var walletLabelTextField: UITextField!
  @IBOutlet weak var walletAddressTextField: UITextField!

  @IBOutlet weak var residentialAddressTextLabel: UILabel!
  @IBOutlet weak var residentialAddressTextField: UITextField!
  @IBOutlet weak var countryOfResidenceTextField: UITextField!
  @IBOutlet weak var cityTextField: UITextField!
  @IBOutlet weak var postalCodeTextField: UITextField!

  @IBOutlet weak var proofOfAddressTextLabel: UILabel!
  @IBOutlet weak var proofOfAddressDescTextLabel: UILabel!
  @IBOutlet weak var proofAddressDocTypeTextField: UITextField!
  @IBOutlet weak var uploadProofAddressDocButton: UIButton!
  fileprivate var proofAddressImage: UIImage?
  @IBOutlet weak var proofOfAddressContainerView: UIView!
  @IBOutlet weak var heightConstraintForProofOfAddressContainerView: NSLayoutConstraint!
  @IBOutlet weak var proofOfAddressImageView: UIImageView!
  @IBOutlet weak var topPaddingConstraintProofOfAddressImageView: NSLayoutConstraint!

  @IBOutlet weak var primarySourceOfFundTextLabel: UILabel!
  @IBOutlet weak var primaraySourceOfFundDescTextLabel: UILabel!
  @IBOutlet weak var primarySourceOfFundTextField: UITextField!

  @IBOutlet weak var optionalDataView: KYCPersonalOptionalDataView!
  @IBOutlet weak var heightConstraintForOptionalData: NSLayoutConstraint!

  @IBOutlet weak var nextButton: UIButton!

  fileprivate var fakeTextField: UITextField = UITextField(frame: CGRect.zero)
  fileprivate var currentValue: String = ""
  fileprivate var dataPickerType: Int = 0
  fileprivate var pickerViewController: KYCSelectOptionViewController?

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

  lazy var proofAddressDocTypePickerView: UIPickerView = {
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
  fileprivate var imagePicker: UIImagePickerController = UIImagePickerController()

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

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.optionalDataView.layoutSubviews()
  }

  fileprivate func setupUI() {
    self.setupDataContent()
    self.setupWalletsDataView()
    self.setupAddressDetails()
    self.setupProofOfAddress()
    self.setupSourceOfFunds()
    self.setupOptionalData()
  }

  fileprivate func setupDataContent() {
    self.firstNameTextField.placeholder = NSLocalizedString("first.name", value: "First Name", comment: "")
    self.lastNameTextField.placeholder = NSLocalizedString("last.name", value: "Last Name", comment: "")
    self.genderTextLabel.text = NSLocalizedString("gender", value: "Gender", comment: "")
    self.maleTextLabel.text = NSLocalizedString("male", value: "Male", comment: "")
    self.femaleTextLabel.text = NSLocalizedString("female", value: "Female", comment: "")
    self.dateOfBirthTextField.placeholder = "\(NSLocalizedString("date.of.birth", value: "Date of birth", comment: "")) (YYYY-MM-DD)"
    self.nationalityTextField.placeholder = NSLocalizedString("nationality", value: "Nationality", comment: "")
    self.mywalletsLabel.text = NSLocalizedString("my.wallets", value: "My wallet(s)", comment: "")
    self.maximumWalletsLabel.text = NSLocalizedString("maximum.three.wallets", value: "Maximum 3 wallets", comment: "")
    self.walletLabelTextField.placeholder = NSLocalizedString("label", value: "Label", comment: "")
    self.walletAddressTextField.placeholder = NSLocalizedString("address", value: "Address", comment: "")
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
    self.addWalletButton.setTitle(
      NSLocalizedString("add", value: "Add", comment: ""),
      for: .normal
    )
    self.noWalletsTextLabel.text = NSLocalizedString("you.have.not.added.any.wallets.yet", value: "You haven't added any wallets yet.", comment: "")

    self.walletsTableView.register(UITableViewCell.self, forCellReuseIdentifier: kWalletTableViewCellID)
    self.walletsTableView.rowHeight = kWalletCellRowHeight
    self.walletsTableView.delegate = self
    self.walletsTableView.dataSource = self
    self.updateWalletsData()

    self.nextButton.setTitle(NSLocalizedString("next", value: "Next", comment: ""), for: .normal)
    self.nextButton.rounded(radius: 4.0)
  }

  fileprivate func setupAddressDetails() {
    self.residentialAddressTextLabel.text = NSLocalizedString(
      "residential.address",
      value: "Residential Address",
      comment: ""
    )
    self.residentialAddressTextField.placeholder = NSLocalizedString(
      "street.address.apartment.unit",
      value: "Street address, P.O. box, apartment, suite, unit, building, floor,…",
      comment: ""
    )
    self.countryOfResidenceTextField.placeholder = NSLocalizedString("country.of.residence", value: "Country of Residence", comment: "")
    self.cityTextField.placeholder = NSLocalizedString("city", value: "City", comment: "")
    self.postalCodeTextField.placeholder = NSLocalizedString("postal.zip.code", value: "Postal / Zip Code", comment: "")
  }

  fileprivate func setupProofOfAddress() {
    self.proofOfAddressTextLabel.text = NSLocalizedString("proof.of.address", value: "Proof of Address", comment: "").uppercased()
    self.proofOfAddressDescTextLabel.text = NSLocalizedString(
      "document.must.display.your.name.and.address",
      value: "Document must display your name and current residential address in 6 months",
      comment: ""
    )
    self.proofAddressDocTypeTextField.placeholder = NSLocalizedString("document.types", value: "Document Types", comment: "")
    self.uploadProofAddressDocButton.setTitle(
      NSLocalizedString("upload.document", value: "Upload Document", comment: ""),
      for: .normal
    )
    self.uploadProofAddressDocButton.rounded(color: UIColor.Kyber.border, width: 1.0, radius: 4.0)
    self.heightConstraintForProofOfAddressContainerView.constant = 0.0
    self.topPaddingConstraintProofOfAddressImageView.constant = 0.0
    self.proofOfAddressImageView.image = nil
  }

  fileprivate func setupSourceOfFunds() {
    self.primarySourceOfFundTextLabel.text = NSLocalizedString("primary.source.of.funds", value: "Primary source of funds", comment: "").uppercased()
    self.primaraySourceOfFundDescTextLabel.text = NSLocalizedString(
      "primary.source.of.funds.desc",
      value: "Explain: Why should users fill up these optional fields???",
      comment: ""
    )
    self.primarySourceOfFundTextField.placeholder = NSLocalizedString("source.of.funds", value: "Source of Funds", comment: "")
  }

  fileprivate func setupOptionalData() {
    self.optionalDataView.collapse()
    self.optionalDataView.delegate = self
    self.heightConstraintForOptionalData.constant = self.optionalDataView.height
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
    self.dataPickerType = 0
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
    self.dataPickerType = 1
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

  @IBAction func proofAddressChooseDocumentTypeButtonPressed(_ sender: Any) {
    self.dataPickerType = 2
    self.fakeTextField.inputView = self.countryPickerView

    self.fakeTextField.inputAccessoryView = self.toolBar
    self.currentValue = self.proofAddressDocTypeTextField.text ?? ""

    if let id = self.viewModel.proofOfAddressTypes.index(of: self.currentValue) {
      self.currentValue = self.viewModel.proofOfAddressTypes[id]
    } else {
      self.currentValue = self.viewModel.proofOfAddressTypes[0]
    }

    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func qrcodeButtonPressed(_ sender: Any) {
    let qrcodeReader = QRCodeReaderViewController()
    qrcodeReader.delegate = self
    self.present(qrcodeReader, animated: true, completion: nil)
  }

  @IBAction func uploadProofOfAddressDocButtonPressed(_ sender: Any) {
    self.openImagePickerController()
  }

  @IBAction func addWalletButtonPressed(_ sender: Any) {
    guard let label = self.walletLabelTextField.text, !label.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.wallet.label", value: "Please enter a valid wallet label", comment: ""),
        time: 1.5
      )
      return
    }
    guard let address = self.walletAddressTextField.text, Address(string: address) != nil else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.input", value: "Invalid Input", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.address", value: "Please enter a valid address", comment: ""),
        time: 1.5
      )
      return
    }
    self.displayLoading(text: NSLocalizedString("checking", value: "Checking", comment: ""), animated: true)
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
            with: NSLocalizedString("address.existed", value: "Address existed", comment: ""),
            message: NSLocalizedString("your.addres.has.already.added", value: "Your address has already added.", comment: ""),
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
        with: NSLocalizedString("invalid.name", value: "Invalid name", comment: ""),
        message: NSLocalizedString("please.enter.a.valid.name", value: "Please enter a valid name", comment: ""),
        time: 1.5
      )
      return
    }
    // Check gender selected
    guard !self.viewModel.gender.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.gender", value: "Invalid gender", comment: ""),
        message: NSLocalizedString("please.select.your.gender.to.continue", value: "Please select your gender to continue", comment: ""),
        time: 1.5
      )
      return
    }
    // Check date of birth
    guard !self.viewModel.dob.isEmpty else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.date.of.birth", value: "Invalid date of birth", comment: ""),
        message: NSLocalizedString("please.select.your.date.of.birth.to.continue", value: "Please select your date of birth to continue", comment: ""),
        time: 1.5
      )
      return
    }
    // Check nationality
    let nationality = self.nationalityTextField.text ?? ""
    guard self.viewModel.nationalities.contains(nationality) else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.nationality", value: "Invalid nationality", comment: ""),
        message: NSLocalizedString("please.enter.select.a.valid.nationality.to.continue", value: "Please enter/select a valid nationality to continue", comment: ""),
        time: 1.5
      )
      return
    }
    // Check country of residences
    let country = self.countryOfResidenceTextField.text ?? ""
    guard self.viewModel.countries.contains(country) else {
      self.showWarningTopBannerMessage(
        with: NSLocalizedString("invalid.country", value: "Invalid country", comment: ""),
        message: NSLocalizedString("please.enter.select.a.valid.country.to.continue", value: "Please enter/select a valid country to continue", comment: ""),
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
    if self.dataPickerType == 0 {
      self.nationalityTextField.text = self.currentValue
    } else if self.dataPickerType == 1 {
      self.countryOfResidenceTextField.text = self.currentValue
    } else if self.dataPickerType == 2 {
      self.proofAddressDocTypeTextField.text = self.currentValue
    } else if self.dataPickerType == 3 {
      self.primarySourceOfFundTextField.text = self.currentValue
    }
  }

  @objc func countryPickerCancelPressed(_ sender: Any) {
    self.fakeTextField.resignFirstResponder()
  }

  @IBAction func primarySourceOfFundButtonPressed(_ sender: Any) {
    self.dataPickerType = 3
    self.fakeTextField.inputView = self.countryPickerView

    self.fakeTextField.inputAccessoryView = self.toolBar
    self.currentValue = self.primarySourceOfFundTextField.text ?? ""

    if let id = self.viewModel.sourceFunds.index(of: self.currentValue) {
      self.currentValue = self.viewModel.sourceFunds[id]
    } else {
      self.currentValue = self.viewModel.sourceFunds[0]
    }

    self.fakeTextField.becomeFirstResponder()
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

  fileprivate func openImagePickerController() {
    let alertController = UIAlertController(
      title: NSLocalizedString("choose.method", value: "Choose Method", comment: ""),
      message: NSLocalizedString("where.do.you.want.to.get.your.image", value: "Where do you want to get your image?", comment: ""),
      preferredStyle: .alert
    )
    alertController.addAction(UIAlertAction(title: NSLocalizedString("camera", value: "Camera", comment: ""), style: .default, handler: { _ in
      self.openImagePickerCamera()
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("photo.library", value: "Photo Library", comment: ""), style: .default, handler: { _ in
      self.openImagePickerPhotoLibrary()
    }))
    alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .destructive, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }

  fileprivate func openImagePickerCamera() {
    self.imagePicker = UIImagePickerController()
    self.imagePicker.mediaTypes = [kUTTypeImage as String]
    self.imagePicker.sourceType = .camera
    self.imagePicker.cameraFlashMode = .off
    self.imagePicker.videoQuality = .typeHigh
    self.imagePicker.delegate = self
    self.navigationController?.present(self.imagePicker, animated: true, completion: nil)
  }

  fileprivate func openImagePickerPhotoLibrary() {
    self.imagePicker.mediaTypes = [kUTTypeImage as String]
    self.imagePicker.sourceType = .photoLibrary
    self.imagePicker.delegate = self
    self.navigationController?.present(self.imagePicker, animated: true, completion: nil)
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
    let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("remove", value: "Remove", comment: "")) { (_, _) in
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
    if self.dataPickerType == 0 {
      self.currentValue = self.viewModel.nationalities[row]
    } else if self.dataPickerType == 1 {
      self.currentValue = self.viewModel.countries[row]
    } else if self.dataPickerType == 2 {
      self.currentValue = self.viewModel.proofOfAddressTypes[row]
    } else if self.dataPickerType == 3 {
      self.currentValue = self.viewModel.sourceFunds[row]
    }
  }
}

extension KYCPersonalInfoViewController: UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    if self.dataPickerType == 0 {
      return self.viewModel.nationalities.count
    } else if self.dataPickerType == 1 {
      return self.viewModel.countries.count
    } else if self.dataPickerType == 2 {
      return self.viewModel.proofOfAddressTypes.count
    } else if self.dataPickerType == 3 {
      return self.viewModel.sourceFunds.count
    }
    return 0
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
      if self.dataPickerType == 0 {
        return self.viewModel.nationalities[row]
      } else if self.dataPickerType == 1 {
        return self.viewModel.countries[row]
      } else if self.dataPickerType == 2 {
        return self.viewModel.proofOfAddressTypes[row]
      } else if self.dataPickerType == 3 {
        return self.viewModel.sourceFunds[row]
      }
      return ""
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

extension KYCPersonalInfoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true, completion: nil)
  }

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
    picker.dismiss(animated: true) {
      guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
        return
      }
      self.updateProofAddressDocumentType(with: image)
    }
  }

  fileprivate func updateProofAddressDocumentType(with image: UIImage) {
    let width = self.proofOfAddressContainerView.frame.width - 48.0
    let height = image.size.height / image.size.width * width
    self.proofOfAddressImageView.image = image.resizeImage(to: CGSize(width: width, height: height))
    self.topPaddingConstraintProofOfAddressImageView.constant = 24.0
    self.heightConstraintForProofOfAddressContainerView.constant = height + 24.0 * 2.0
    self.proofAddressImage = image.compress(to: 0.99)
    self.view.layoutIfNeeded()
  }
}

extension KYCPersonalInfoViewController: KYCPersonalOptionalDataViewDelegate {
  func kycPersonalOptionalDataViewActionPressed(isCollapsed: Bool) {
    if isCollapsed {
      self.optionalDataView.expand()
    } else {
      self.optionalDataView.collapse()
    }
    self.heightConstraintForOptionalData.constant = self.optionalDataView.height
    self.view.layoutSubviews()
  }

  func kycPersonalOptionalDataViewOccupationPressed(current: String) {
    self.dataPickerType = 5
    self.pickerViewController = KYCSelectOptionViewController(
      title: NSLocalizedString("occupation.code", value: "Occupation code", comment: ""), dataSources: Array(self.viewModel.occupationCodes.values)
    )
    self.pickerViewController?.delegate = self
    self.parent?.navigationController?.pushViewController(self.pickerViewController!, animated: true)
  }

  func kycPersonalOptionalDataViewIndustryPressed(current: String) {
    self.dataPickerType = 6
    self.pickerViewController = KYCSelectOptionViewController(
      title: NSLocalizedString("industry.code", value: "Industry code", comment: ""), dataSources: Array(self.viewModel.industryCodes.values)
    )
    self.pickerViewController?.delegate = self
    self.parent?.navigationController?.pushViewController(self.pickerViewController!, animated: true)
  }

  func kycPersonalOptionalDataViewCountryPressed(current: String) {
    self.dataPickerType = 7
    self.pickerViewController = KYCSelectOptionViewController(
      title: NSLocalizedString("country", value: "Country", comment: ""), dataSources: self.viewModel.countries
    )
    self.pickerViewController?.delegate = self
    self.parent?.navigationController?.pushViewController(self.pickerViewController!, animated: true)
  }
}

extension KYCPersonalInfoViewController: KYCSelectOptionViewControllerDelegate {
  func kycSelectOptionViewControllerShouldBack(_ controller: KYCSelectOptionViewController) {
    controller.navigationController?.popViewController(animated: true)
  }

  func kycSelectOptionViewController(_ controller: KYCSelectOptionViewController, didSelect data: String) {
    controller.navigationController?.popViewController(animated: true, completion: {
      if self.dataPickerType == 5 {
        for (key, value) in self.viewModel.occupationCodes where value == data {
          self.optionalDataView.updateOccupationCodeData(key)
        }
      } else if self.dataPickerType == 6 {
        for (key, value) in self.viewModel.industryCodes where value == data {
          self.optionalDataView.updateIndustryCodeData(key)
        }
      } else if self.dataPickerType == 7 {
        self.optionalDataView.updateCountryData(data)
      }
    })
  }
}
