// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNDebugMenuViewController: KNBaseViewController {

  @IBOutlet weak var internalSegmentedControl: UISegmentedControl!
  @IBOutlet weak var internalCacheEndpointLabel: UILabel!
  
  @IBOutlet weak var environmentSegmentedControl: UISegmentedControl!
  @IBOutlet weak var environmentEndpointLabel: UILabel!
  @IBOutlet weak var envNetworkAddressLabel: UILabel!
  @IBOutlet weak var envReserveAddressLabel: UILabel!

  fileprivate let internalEndpoint = KNEnvironment.internalBaseEndpoint
  fileprivate let environment = KNEnvironment.default

  fileprivate var newInternalEndpoint: String = KNEnvironment.internalBaseEndpoint
  fileprivate var newEnvironment: KNEnvironment = KNEnvironment.default

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  fileprivate func setupUI() {
    self.setupInternalCacheEndpoint()
    self.setupEnvironment()
  }

  fileprivate func setupInternalCacheEndpoint() {
    self.internalSegmentedControl.rounded(color: .clear, width: 0, radius: 5.0)
    self.internalCacheEndpointLabel.text = internalEndpoint
    if internalEndpoint == "https://staging-cache.kyber.network" {
      self.internalSegmentedControl.selectedSegmentIndex = 0
    } else {
      self.internalSegmentedControl.selectedSegmentIndex = 1
    }
  }

  fileprivate func setupEnvironment() {
    self.environmentSegmentedControl.rounded(color: .clear, width: 0, radius: 5.0)
    self.environmentSegmentedControl.selectedSegmentIndex = self.environment.rawValue
    self.updateEnvironmentData()
  }

  @IBAction func backPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func applyPressed(_ sender: Any) {
    if self.newEnvironment == self.environment && self.newInternalEndpoint == self.internalEndpoint {
      return
    }
    let alertController = UIAlertController(title: "", message: "Applying changes will restart the app", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.addAction(UIAlertAction(title: "Apply", style: .default, handler: { _ in
      KNAppTracker.updateInternalCacheEndpoint(value: self.newInternalEndpoint)
      KNAppTracker.updateExternalEnvironment(self.newEnvironment)
      exit(0)
    }))
    self.present(alertController, animated: true, completion: nil)
  }

  @IBAction func internalSegmentedControlDidChange(_ sender: UISegmentedControl) {
    if sender.selectedSegmentIndex == 0 {
      self.newInternalEndpoint = "https://staging-cache.kyber.network"
    } else {
      self.newInternalEndpoint = "https://production-cache.kyber.network"
    }
    self.internalCacheEndpointLabel.text = self.newInternalEndpoint
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
}
