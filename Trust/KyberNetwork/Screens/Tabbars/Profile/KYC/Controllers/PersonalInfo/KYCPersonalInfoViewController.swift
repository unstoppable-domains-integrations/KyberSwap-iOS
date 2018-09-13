// Copyright SIX DAY LLC. All rights reserved.

import UIKit

enum KYCPersonalInfoViewEvent {
  case next
}

class KYCPersonalInfoViewModel {

  let user: IEOUser
  let nationalities: [String]
  let countries: [String]

  fileprivate(set) var gender: String = ""
  fileprivate(set) var dob: String = ""

  fileprivate(set) var addresses: [String] = []

  init(user: IEOUser) {
    self.user = user
    self.addresses = user.registeredAddress.map({ return $0 })
    let json = KNJSONLoaderUtil.jsonDataFromFile(with: "kyc_data") ?? [:]
    self.nationalities = json["nationalities"] as? [String] ?? []
    self.countries = json["countries"] as? [String] ?? []
  }

  func updateGender(_ gender: String) { self.gender = gender }
  func updateDoB(_ dob: String) { self.dob = dob }
  func removeAddress(_ address: String) {
    if let id = self.addresses.index(of: address) {
      self.addresses.remove(at: id)
    }
  }

  @discardableResult
  func addAddress(_ address: String) -> Bool {
    guard !self.addresses.contains(address) else { return false }
    self.addresses.insert(address, at: 0)
    return true
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
    self.view.addSubview(self.fakeTextField)
  }

  fileprivate func setupWalletsDataView() {
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
    self.viewModel.updateGender(self.viewModel.gender == "male" ? "" : "male")
    self.updateGenderUI()
  }

  @IBAction func femaleButtonPressed(_ sender: Any) {
    self.viewModel.updateGender(self.viewModel.gender == "female" ? "" : "female")
    self.updateGenderUI()
  }

  fileprivate func updateGenderUI() {
    self.maleButton.rounded(
      color: self.viewModel.gender == "male" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.gender == "male" ? 6.0 : 1.0,
      radius: self.maleButton.frame.height / 2.0
    )
    self.femaleButton.rounded(
      color: self.viewModel.gender == "female" ? UIColor.Kyber.shamrock : UIColor.Kyber.border,
      width: self.viewModel.gender == "female" ? 6.0 : 1.0,
      radius: self.maleButton.frame.height / 2.0
    )
  }

  @IBAction func nationalityButtonPressed(_ sender: Any) {
    self.isSelectNationality = true
    self.fakeTextField.inputView = self.countryPickerView

    self.fakeTextField.inputAccessoryView = self.toolBar
    self.currentValue = self.nationalityTextField.text ?? ""

    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func countryOfResidenceButtonPressed(_ sender: Any) {
    self.isSelectNationality = false
    self.fakeTextField.inputView = self.countryPickerView

    self.fakeTextField.inputAccessoryView = self.toolBar
    self.currentValue = self.countryOfResidenceTextField.text ?? ""

    self.fakeTextField.becomeFirstResponder()
  }

  @IBAction func addWalletButtonPressed(_ sender: Any) {
    //TODO: Open add wallet view
  }

  @IBAction func nextButtonPressed(_ sender: Any) {
    //TODO: Validate information here

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
    self.delegate?.kycPersonalInfoViewController(self, run: .next)
  }

  @objc func dateOfBirthDidChange(_ sender: Any) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd/MM/yy"
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
    if self.viewModel.addresses.isEmpty {
      self.noWalletsTextLabel.isHidden = false
      self.walletsTableView.isHidden = true
      self.heightConstraintWalletsDataView.constant = 60.0
    } else {
      self.heightConstraintWalletsDataView.constant = CGFloat(self.viewModel.addresses.count) * kWalletCellRowHeight
      self.noWalletsTextLabel.isHidden = true
      self.walletsTableView.isHidden = false
    }
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
    return self.viewModel.addresses.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }

  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Remove") { (_, _) in
      self.removeAddress(at: indexPath.row)
    }
    deleteAction.backgroundColor = UIColor.Kyber.fire
    return [deleteAction]
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: kWalletTableViewCellID, for: indexPath)
    cell.textLabel?.isUserInteractionEnabled = false
    let addresses = self.viewModel.addresses
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

  fileprivate func removeAddress(at row: Int) {
    //TODO: Remove addresses
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
