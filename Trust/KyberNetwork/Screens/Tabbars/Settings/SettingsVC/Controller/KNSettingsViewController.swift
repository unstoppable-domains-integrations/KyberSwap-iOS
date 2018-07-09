// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Eureka
import StoreKit

enum KNSettingsViewEvent {
  case exit
  case close
  case backUp
  case clickWallets
  case passcodeDidChange(isOn: Bool)
}

protocol KNSettingsViewControllerDelegate: class {
  func settingsViewController(_ controller: KNSettingsViewController, run event: KNSettingsViewEvent)
}

class KNSettingsViewController: FormViewController {

  weak var delegate: KNSettingsViewControllerDelegate?
  fileprivate var address: String

  fileprivate var passcodeRow: SwitchRow!
  fileprivate var walletsCell: ButtonRow!

  init(address: String) {
    self.address = address
    super.init(nibName: nil, bundle: nil)
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

    form = Form()
    var accountSection = Section("Account")
    self.walletsCell = AppFormAppearance.button { button in
      button.cellStyle = .value1
    }.onCellSelection { [unowned self] _, _ in
      self.delegate?.settingsViewController(self, run: .clickWallets)
    }.cellUpdate { cell, _ in
      cell.textLabel?.textColor = .black
      cell.imageView?.image = UIImage(named: "settings_wallet")
      cell.textLabel?.text = "Wallets".toBeLocalised()
      cell.detailTextLabel?.text = String(self.address.prefix(16)) + "..."
      cell.accessoryType = .disclosureIndicator
    }
    accountSection += [self.walletsCell]
    accountSection <<< AppFormAppearance.button { button in
      button.cellStyle = .value1
    }.onCellSelection { [unowned self] _, _ in
      self.delegate?.settingsViewController(self, run: .backUp)
    }.cellUpdate { cell, _ in
      cell.textLabel?.textColor = .black
      cell.imageView?.image = UIImage(named: "settings_export")
      cell.textLabel?.text = "Backup".toBeLocalised()
      cell.accessoryType = .disclosureIndicator
    }
    form += [accountSection]

//    var securitySection = Section("Security")
//    form += [securitySection]
//    self.passcodeRow = SwitchRow("SwitchRow") {
//      $0.title = "TouchID/FaceID/Passcode".toBeLocalised()
//      $0.value = KNPasscodeUtil.shared.currentPasscode() != nil
//    }.onChange { [unowned self] row in
//      self.delegate?.settingsViewController(self, run: .passcodeDidChange(isOn: row.value == true))
//    }.cellSetup { cell, _ in
//      cell.imageView?.image = UIImage(named: "settings_lock")
//    }
//    securitySection += [self.passcodeRow]

    form +++ Section()
    <<< TextRow {
      $0.title = "Version".toBeLocalised()
      $0.value = Bundle.main.fullVersion
      $0.disabled = true
    }

    form +++ Section()
    <<< ButtonRow {
      $0.title = "Exit".toBeLocalised()
    }.onCellSelection({ [unowned self] _, _ in
      self.delegate?.settingsViewController(self, run: .exit)
    })
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "Settings".toBeLocalised()
//    self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "close_white_icon"), style: .plain, target: self, action: #selector(self.closeButtonPressed(_:)))
//    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  @objc func closeButtonPressed(_ sender: Any) {
    self.delegate?.settingsViewController(self, run: .close)
  }

  func userDidCancelCreatePasscode() {
    self.passcodeRow.value = false
    self.passcodeRow.updateCell()
  }

  func userDidSelectNewWallet(with address: String) {
    self.address = address
    self.walletsCell.cell.detailTextLabel?.text = String(self.address.prefix(16)) + "..."
    self.walletsCell.updateCell()
  }
}
