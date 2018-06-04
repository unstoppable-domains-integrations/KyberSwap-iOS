// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNDebugMenuViewController: KNBaseViewController {

  @IBOutlet weak var environmentSegmentedControl: UISegmentedControl!
  @IBOutlet weak var environmentEndpointLabel: UILabel!
  @IBOutlet weak var envNetworkAddressLabel: UILabel!
  @IBOutlet weak var envReserveAddressLabel: UILabel!

  @IBOutlet weak var walletHeaderViewSegmentedControl: UISegmentedControl!

  fileprivate let walletHeaderView = KNAppTracker.walletHeaderView()
  fileprivate let environment = KNEnvironment.default

  fileprivate var newEnvironment: KNEnvironment = KNEnvironment.default
  fileprivate var newWalletHeaderView: String = KNAppTracker.walletHeaderView()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupEnvironment()
  }

  fileprivate func setupEnvironment() {
    self.environmentSegmentedControl.rounded(color: .clear, width: 0, radius: 5.0)
    self.environmentSegmentedControl.selectedSegmentIndex = self.environment.rawValue
    self.updateWalletHeaderView()
    self.updateEnvironmentData()
  }

  @IBAction func backPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func applyPressed(_ sender: Any) {
    if self.newEnvironment == self.environment && self.newWalletHeaderView == self.walletHeaderView {
      self.dismiss(animated: true, completion: nil)
      return
    }
    let alertController = UIAlertController(title: "", message: "Applying changes environment could restart the app", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { _ in
      KNAppTracker.updateExternalEnvironment(self.newEnvironment)
      KNAppTracker.updateWalletHeaderView(self.newWalletHeaderView)
      KNNotificationUtil.postNotification(for: kWalletHeaderViewDidChangeTypeNotificationKey)
      if self.newEnvironment != self.environment {
        exit(0)
      } else {
        self.dismiss(animated: true, completion: nil)
      }
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func environmentSegmentedControl(_ sender: UISegmentedControl) {
    if let env = KNEnvironment(rawValue: sender.selectedSegmentIndex) {
      self.newEnvironment = env
    }
    self.updateEnvironmentData()
  }

  fileprivate func updateEnvironmentData() {
    self.environmentEndpointLabel.text = self.newEnvironment.knCustomRPC?.customRPC.endpoint
    self.envNetworkAddressLabel.text = "Network Address: \(self.newEnvironment.knCustomRPC?.networkAddress ?? "")"
    self.envReserveAddressLabel.text = "Reserve Address: \(self.newEnvironment.knCustomRPC?.reserveAddress ?? "")"
  }

  @IBAction func walletHeaderViewSegmentedControlDidChange(_ sender: Any) {
    if self.walletHeaderViewSegmentedControl.selectedSegmentIndex == 0 {
      self.newWalletHeaderView = "white"
    } else {
      self.newWalletHeaderView = "green"
    }
    self.updateWalletHeaderView()
  }

  fileprivate func updateWalletHeaderView() {
    if self.newWalletHeaderView == "white" {
      self.walletHeaderViewSegmentedControl.selectedSegmentIndex = 0
    } else {
      self.walletHeaderViewSegmentedControl.selectedSegmentIndex = 1
    }
  }
}
