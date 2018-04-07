// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNSettingsViewControllerDelegate: class {
  func settingsViewControllerDidClickExit()
  func settingsViewControllerBackUpButtonPressed()
}

class KNSettingsViewController: KNBaseViewController {

  fileprivate weak var delegate: KNSettingsViewControllerDelegate?

  @IBOutlet weak var backupButton: UIButton!

  init(delegate: KNSettingsViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNSettingsViewController.className, bundle: nil)
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
    self.setupBackup()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "History".toBeLocalised()
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupBackup() {
    self.backupButton.rounded(color: .clear, width: 0, radius: 5.0)
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.settingsViewControllerDidClickExit()
  }

  @IBAction func backupButtonPressed(_ sender: Any) {
    self.delegate?.settingsViewControllerBackUpButtonPressed()
  }
}
