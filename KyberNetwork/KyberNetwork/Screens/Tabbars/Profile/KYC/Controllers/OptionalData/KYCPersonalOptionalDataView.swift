// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KYCPersonalOptionalDataViewDelegate: class {
  func kycPersonalOptionalDataViewActionPressed(isCollapsed: Bool)
  func kycPersonalOptionalDataViewOccupationPressed(current: String)
  func kycPersonalOptionalDataViewIndustryPressed(current: String)
  func kycPersonalOptionalDataViewCountryPressed(current: String)
}

class KYCPersonalOptionalDataViewModel: NSObject {
  var isCollapsed: Bool = true
  var occupationCode: String = ""
  var industryCode: String = ""
  var country: String = ""
  var hasTaxIDNumber: Bool = false

  var buttonTitle: String {
    if isCollapsed { return NSLocalizedString("see.more", value: "See more", comment: "") }
    return NSLocalizedString("see.less", value: "See less", comment: "")
  }
}

class KYCPersonalOptionalDataView: XibLoaderView {

  weak var delegate: KYCPersonalOptionalDataViewDelegate?
  fileprivate(set) var viewModel: KYCPersonalOptionalDataViewModel = KYCPersonalOptionalDataViewModel()

  @IBOutlet weak var actionButton: UIButton!
  @IBOutlet weak var occupationCodeTextField: UITextField!
  @IBOutlet weak var industryCodeTextField: UITextField!
  @IBOutlet weak var pleaseIndicateYourTaxResidencyTextLabel: UILabel!
  @IBOutlet weak var reasonCollectingInformationTextLabel: UILabel!
  @IBOutlet weak var countryTextField: UITextField!
  @IBOutlet weak var haveTaxIDNoTextLabel: UILabel!
  @IBOutlet weak var yesLabel: UILabel!
  @IBOutlet weak var noLabel: UILabel!
  @IBOutlet weak var yesButton: UIButton!
  @IBOutlet weak var noButton: UIButton!
  @IBOutlet weak var taxIDNumberTextField: UITextField!

  @IBOutlet var textFieldHeightConstraints: [NSLayoutConstraint]!
  @IBOutlet var dropDownButtonHeightConstraints: [NSLayoutConstraint]!
  @IBOutlet var underlineViewHeightConstraints: [NSLayoutConstraint]!
  @IBOutlet var bigPaddingHeightConstraints: [NSLayoutConstraint]!
  @IBOutlet var smallPaddingHeightConstraints: [NSLayoutConstraint]!
  @IBOutlet var selectTaxIDNoButtonHeightConstraints: [NSLayoutConstraint]!

  override func commonInit() {
    super.commonInit()
    self.actionButton.semanticContentAttribute = .forceRightToLeft
    self.actionButton.setTitle(self.viewModel.buttonTitle, for: .normal)

    self.updateHaveTaxIDNumber()
    self.setupTexts()

    let yesTap = UITapGestureRecognizer(target: self, action: #selector(self.yesButtonPressed(_:)))
    self.yesLabel.isUserInteractionEnabled = true
    self.yesLabel.addGestureRecognizer(yesTap)

    let noTap = UITapGestureRecognizer(target: self, action: #selector(self.noButtonPressed(_:)))
    self.noLabel.isUserInteractionEnabled = true
    self.noLabel.addGestureRecognizer(noTap)
  }

  var height: CGFloat {
    if self.viewModel.isCollapsed { return 60.0 }
    var result: CGFloat = 60.0
    result += CGFloat(self.textFieldHeightConstraints.count) * 46.0
    result += CGFloat(self.bigPaddingHeightConstraints.count) * 32.0
    result += CGFloat(self.smallPaddingHeightConstraints.count) * 8.0
    result += 32.0 // select yes/no button height
    result += self.pleaseIndicateYourTaxResidencyTextLabel.frame.height
    result += self.reasonCollectingInformationTextLabel.frame.height
    result += self.haveTaxIDNoTextLabel.frame.height
    return result
  }

  func collapse() {
    self.viewModel.isCollapsed = true
    self.textFieldHeightConstraints.forEach { $0.constant = 0.0 }
    self.dropDownButtonHeightConstraints.forEach { $0.constant = 0.0 }
    self.underlineViewHeightConstraints.forEach { $0.constant = 0.0 }
    self.bigPaddingHeightConstraints.forEach { $0.constant = 0.0 }
    self.smallPaddingHeightConstraints.forEach { $0.constant = 0.0 }
    self.selectTaxIDNoButtonHeightConstraints.forEach { $0.constant = 0.0 }
    self.actionButton.setTitle(self.viewModel.buttonTitle, for: .normal)
    self.resetTexts()
    self.layoutIfNeeded()
  }

  func expand() {
    self.viewModel.isCollapsed = false
    self.textFieldHeightConstraints.forEach { $0.constant = 46.0 }
    self.dropDownButtonHeightConstraints.forEach { $0.constant = 24.0 }
    self.underlineViewHeightConstraints.forEach { $0.constant = 1.0 }
    self.bigPaddingHeightConstraints.forEach { $0.constant = 32.0 }
    self.smallPaddingHeightConstraints.forEach { $0.constant = 8.0 }
    self.selectTaxIDNoButtonHeightConstraints.forEach { $0.constant = 24.0 }
    self.actionButton.setTitle(self.viewModel.buttonTitle, for: .normal)
    self.setupTexts()
    self.layoutIfNeeded()
  }

  func updateCountryData(_ data: String) {
    self.countryTextField.text = data
    self.viewModel.country = data
    self.layoutIfNeeded()
  }

  func updateOccupationCodeData(_ data: String, value: String) {
    self.occupationCodeTextField.text = value.isEmpty ? data : "\(data) - \(value)"
    self.viewModel.occupationCode = data
    self.layoutIfNeeded()
  }

  func updateIndustryCodeData(_ data: String, value: String) {
    self.industryCodeTextField.text = value.isEmpty ? data : "\(data) - \(value)"
    self.viewModel.industryCode = data
    self.layoutIfNeeded()
  }

  func updateTaxIDNumber(_ data: String?) {
    self.viewModel.hasTaxIDNumber = data != nil
    self.taxIDNumberTextField.text = data
    self.updateHaveTaxIDNumber()
    self.layoutIfNeeded()
  }

  func updateOptionalData(with details: UserKYCDetailsInfo, occupation: String, industry: String) {
    self.updateOccupationCodeData(details.occupationCode, value: occupation)
    self.updateIndustryCodeData(details.industryCode, value: industry)
    self.updateCountryData(details.taxResidencyCountry)
    self.updateTaxIDNumber(details.taxIDNUmber.isEmpty ? nil : details.taxIDNUmber)
    self.layoutIfNeeded()
  }

  fileprivate func setupTexts() {
    self.occupationCodeTextField.placeholder = NSLocalizedString("occupation.code.optional", value: "Occupation code (optional)", comment: "")
    self.industryCodeTextField.placeholder = NSLocalizedString("industry.code.optional", value: "Industry code (optional)", comment: "")
    self.pleaseIndicateYourTaxResidencyTextLabel.text = NSLocalizedString(
      "please.indicate.tax.residency",
      value: "Please indicate your country of Tax Residency (Optional)",
      comment: "")
    self.reasonCollectingInformationTextLabel.text = NSLocalizedString(
      "reason.collecting.country.of.tax.residency",
      value: "We are collecting this information in compliance with the relevant tax regulations.\nHelp us ensure the information is accurate and up to date",
      comment: "")
    self.countryTextField.placeholder = NSLocalizedString("country", value: "Country", comment: "")
    self.haveTaxIDNoTextLabel.text = NSLocalizedString("have.tax.identification.no", value: "Have a Tax Identification No?", comment: "")
    self.yesLabel.text = NSLocalizedString("yes", value: "Yes", comment: "")
    self.noLabel.text = NSLocalizedString("no", value: "No", comment: "")
    self.taxIDNumberTextField.placeholder = NSLocalizedString("tax.identification.no.equivalent", value: "Tax Identification No (TIN) or equivalent", comment: "")

    self.occupationCodeTextField.isHidden = false
    self.industryCodeTextField.isHidden = false
    self.pleaseIndicateYourTaxResidencyTextLabel.isHidden = false
    self.reasonCollectingInformationTextLabel.isHidden = false
    self.countryTextField.isHidden = false
    self.haveTaxIDNoTextLabel.isHidden = false
    self.yesLabel.isHidden = false
    self.noLabel.isHidden = false
    self.taxIDNumberTextField.isHidden = false
  }

  fileprivate func resetTexts() {
    self.occupationCodeTextField.text = ""
    self.industryCodeTextField.text = ""
    self.pleaseIndicateYourTaxResidencyTextLabel.text = ""
    self.reasonCollectingInformationTextLabel.text = ""
    self.countryTextField.text = ""
    self.haveTaxIDNoTextLabel.text = ""
    self.yesLabel.text = ""
    self.noLabel.text = ""
    self.taxIDNumberTextField.text = nil

    self.occupationCodeTextField.isHidden = true
    self.industryCodeTextField.isHidden = true
    self.pleaseIndicateYourTaxResidencyTextLabel.isHidden = true
    self.reasonCollectingInformationTextLabel.isHidden = true
    self.countryTextField.isHidden = true
    self.haveTaxIDNoTextLabel.isHidden = true
    self.yesLabel.isHidden = true
    self.noLabel.isHidden = true
    self.taxIDNumberTextField.isHidden = true
  }

  fileprivate func updateHaveTaxIDNumber() {
    self.yesButton.rounded(
      color: self.viewModel.hasTaxIDNumber ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: self.viewModel.hasTaxIDNumber ? 6.0 : 1.0,
      radius: 12.0
    )
    self.noButton.rounded(
      color: !self.viewModel.hasTaxIDNumber ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: !self.viewModel.hasTaxIDNumber ? 6.0 : 1.0,
      radius: 12.0
    )
    self.taxIDNumberTextField.isEnabled = self.viewModel.hasTaxIDNumber
    if !self.viewModel.hasTaxIDNumber { self.taxIDNumberTextField.text = "" }
    self.layoutIfNeeded()
  }

  func getOccupationCode() -> String { return self.viewModel.occupationCode }
  func getIndustryCode() -> String { return self.viewModel.industryCode }
  func getTaxCountry() -> String { return self.viewModel.country }
  func getHasTaxIDNumber() -> Bool { return self.viewModel.hasTaxIDNumber }
  func getTaxIDNumber() -> String { return self.taxIDNumberTextField.text ?? "" }

  @IBAction func actionButtonPressed(_ sender: Any) {
    self.delegate?.kycPersonalOptionalDataViewActionPressed(isCollapsed: self.viewModel.isCollapsed)
  }

  @IBAction func occupationCodeButtonPressed(_ sender: Any) {
    self.delegate?.kycPersonalOptionalDataViewOccupationPressed(current: self.occupationCodeTextField.text ?? "")
  }

  @IBAction func industryCodeButtonPressed(_ sender: Any) {
    self.delegate?.kycPersonalOptionalDataViewIndustryPressed(current: self.industryCodeTextField.text ?? "")
  }

  @IBAction func countryTaxButtonPressed(_ sender: Any) {
    self.delegate?.kycPersonalOptionalDataViewCountryPressed(current: self.countryTextField.text ?? "")
  }

  @IBAction func yesButtonPressed(_ sender: Any) {
    self.viewModel.hasTaxIDNumber = true
    self.updateHaveTaxIDNumber()
  }

  @IBAction func noButtonPressed(_ sender: Any) {
    self.viewModel.hasTaxIDNumber = false
    self.updateHaveTaxIDNumber()
  }
}
