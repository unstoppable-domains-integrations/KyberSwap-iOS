// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

class KNNewAlertViewModel {
  fileprivate(set) var alert: KNAlertObject?
  fileprivate(set) var currencyType: KWalletCurrencyType = .usd
  fileprivate(set) var token: String = "ETH"
  fileprivate(set) var currentPrice: Double = 0.0
  fileprivate(set) var targetPrice: Double = 0.0

  var displayTokenTitle: String { return "\(token)/\(currencyType.rawValue)" }
  var displayCurrencyTitle: String { return currencyType.rawValue }
  var currentPriceDisplay: String {
    let price = BigInt(currentPrice * pow(10.0, 18.0))
    let display = price.displayRate(decimals: 18)
    return "Current Price: \(display)"
  }

  func update(token: String, currencyType: KWalletCurrencyType) {
    self.token = token
    self.currencyType = currencyType
    self.updateCurrentPrice()
  }

  func updateEditAlert(_ alert: KNAlertObject) {
    self.alert = alert
    self.currencyType = KWalletCurrencyType(rawValue: alert.currency) ?? .usd
    self.token = alert.token
    self.targetPrice = alert.price
    self.updateCurrentPrice()
  }

  func updateTargetPrice(_ price: Double) {
    self.targetPrice = price
  }

  func updateCurrentPrice() {
    guard let tracker = KNTrackerRateStorage.shared.rates.first(where: { $0.tokenSymbol == self.token }) else {
      self.currentPrice = 0.0
      return
    }
    self.currentPrice = self.currencyType == .usd ? tracker.rateUSDNow : tracker.rateETHNow
  }

  func switchCurrencyType() {
    self.currencyType = self.currencyType == .usd ? .eth : .usd
    self.updateCurrentPrice()
  }
}

class KNNewAlertViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!
  @IBOutlet weak var tokenTextLabel: UILabel!
  @IBOutlet weak var tokenButton: UIButton!
  @IBOutlet weak var currencyButton: UIButton!
  @IBOutlet weak var alertPriceTextLabel: UILabel!
  @IBOutlet weak var alertPriceTextField: UITextField!
  @IBOutlet weak var currentPriceTextLabel: UILabel!

  let viewModel: KNNewAlertViewModel = KNNewAlertViewModel()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.currencyButton.setTitle(self.viewModel.currencyType.rawValue, for: .normal)
    self.updateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "currency_\(self.viewModel.currencyType.rawValue)"])
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  func updatePair(token: TokenObject, currencyType: KWalletCurrencyType) {
    self.viewModel.update(token: token.symbol, currencyType: currencyType)
    self.updateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "currency_\(self.viewModel.currencyType.rawValue)"])
  }

  func updateEditAlert(_ alert: KNAlertObject) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "alert_edited"])
    self.viewModel.updateEditAlert(alert)
    self.alertPriceTextField.text = "\(alert.price)"
    self.updateUIs()
  }

  fileprivate func updateUIs() {
    let placeHolder = UIImage(named: "default_token")
    let url = "https://raw.githubusercontent.com/KyberNetwork/KyberNetwork.github.io/master/DesignAssets/tokens/iOS/\(self.viewModel.token.lowercased()).png"
    if let image = UIImage(named: self.viewModel.token.lowercased()) {
      self.tokenButton.setImage(
        image.resizeImage(to: CGSize(width: 36.0, height: 36.0)),
        for: .normal
      )
    } else {
      self.tokenButton.setImage(
        with: url,
        placeHolder: placeHolder,
        size: CGSize(width: 36.0, height: 36.0),
        state: .normal
      )
    }
    self.tokenButton.setTitle(self.viewModel.displayTokenTitle, for: .normal)
    self.currencyButton.setTitle(self.viewModel.displayCurrencyTitle, for: .normal)
    self.currentPriceTextLabel.text = self.viewModel.currentPriceDisplay
  }

  @IBAction func switchCurrencyTypePressed(_ sender: Any) {
    self.viewModel.switchCurrencyType()
    self.updateUIs()
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "currency_\(self.viewModel.currencyType.rawValue)"])
  }

  @IBAction func selectTokenButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "select_token"])
    let viewModel = KNSearchTokenViewModel(
      headerColor: UIColor.Kyber.shamrock,
      supportedTokens: KNSupportedTokenStorage.shared.supportedTokens
    )
    let searchTokenVC = KNSearchTokenViewController(viewModel: viewModel)
    searchTokenVC.loadViewIfNeeded()
    searchTokenVC.delegate = self
    self.navigationController?.pushViewController(searchTokenVC, animated: true)
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "back_button"])
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func screenEdgePanAction(_ sender: UIScreenEdgePanGestureRecognizer
    ) {
    if sender.state == .ended {
      KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "screen_edge_pan"])
      self.navigationController?.popViewController(animated: true)
    }
  }

  @IBAction func saveButtonPressed(_ sender: Any) {
    KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "save_button", "is_added_new_alert": self.viewModel.alert == nil])
    let targetPrice = Double((self.alertPriceTextField.text ?? "").removeGroupSeparator()) ?? 0.0
    self.viewModel.updateTargetPrice(targetPrice)
    if let _ = self.viewModel.alert {
      self.updateAlertSavePressed()
    } else {
      self.createNewAlertSavePressed()
    }
  }

  fileprivate func createNewAlertSavePressed() {
    let alert = KNAlertObject(
      token: self.viewModel.token,
      currency: self.viewModel.currencyType.rawValue,
      price: self.viewModel.targetPrice,
      isAbove: self.viewModel.targetPrice > self.viewModel.currentPrice
    )
    self.displayLoading()
    KNPriceAlertCoordinator.shared.addNewAlert(alert) { [weak self] result in
      guard let `self` = self else { return }
      self.hideLoading()
      switch result {
      case .success:
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: "New alert has been added successfully!".toBeLocalised(),
          time: 1.0
        )
      case .failure(let error):
        KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "create_new_alert_failed", "error": error.prettyError])
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.prettyError,
          time: 1.5
        )
      }
      self.navigationController?.popViewController(animated: true)
    }
  }

  fileprivate func updateAlertSavePressed() {
    var json = self.viewModel.alert?.json ?? [:]
    json["token"] = self.viewModel.token
    json["currency"] = self.viewModel.currencyType.rawValue
    json["price"] = self.viewModel.targetPrice
    json["isAbove"] = self.viewModel.targetPrice > self.viewModel.currentPrice
    json["updatedDate"] = Date().timeIntervalSince1970
    json["state"] = KNAlertState.active.rawValue
    let alert = KNAlertObject(json: json)
    self.displayLoading()
    KNPriceAlertCoordinator.shared.updateAlert(alert) { [weak self] result in
      guard let `self` = self else { return }
      self.hideLoading()
      switch result {
      case .success:
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: "Updated alert successfully!".toBeLocalised(),
          time: 1.0
        )
      case .failure(let error):
        KNCrashlyticsUtil.logCustomEvent(withName: "new_alert", customAttributes: ["type": "update_alert_failed", "error": error.prettyError])
        self.showErrorTopBannerMessage(
          with: NSLocalizedString("error", value: "Error", comment: ""),
          message: error.prettyError,
          time: 1.5
        )
      }
      self.navigationController?.popViewController(animated: true)
    }
  }
}

extension KNNewAlertViewController: KNSearchTokenViewControllerDelegate {
  func searchTokenViewController(_ controller: KNSearchTokenViewController, run event: KNSearchTokenViewEvent) {
    self.navigationController?.popViewController(animated: true, completion: {
      if case .select(let token) = event {
        self.viewModel.update(token: token.symbol, currencyType: self.viewModel.currencyType)
        self.updateUIs()
      }
    })
  }
}
