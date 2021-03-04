//
//  AddTokenCoordinator.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/1/21.
//

import Foundation
import QRCodeReaderViewController

class AddTokenCoordinator: NSObject, Coordinator {
  let navigationController: UINavigationController
  var coordinators: [Coordinator] = []
  
  lazy var rootViewController: AddTokenViewController = {
    let controller = AddTokenViewController()
    controller.delegate = self
    return controller
  }()
  
  init(navigationController: UINavigationController = UINavigationController()) {
    self.navigationController = navigationController
    self.navigationController.setNavigationBarHidden(true, animated: false)
  }
  
  func start() {
    self.navigationController.pushViewController(self.rootViewController, animated: true)
  }
  
  func stop() {
    self.navigationController.popViewController(animated: true)
  }
}

extension AddTokenCoordinator: AddTokenViewControllerDelegate {
  func addTokenViewController(_ controller: AddTokenViewController, run event: AddTokenViewEvent) {
    switch event {
    case .openQR:
      if KNOpenSettingsAllowCamera.openCameraNotAllowAlertIfNeeded(baseVC: controller) {
        return
      }
      let qrcodeReaderVC: QRCodeReaderViewController = {
        let controller = QRCodeReaderViewController()
        controller.delegate = self
        return controller
      }()
      controller.present(qrcodeReaderVC, animated: true, completion: nil)
    case .done(let address, let symbol, let decimals):
      let token = Token(dictionary: ["address": address, "symbol": symbol, "decimals": decimals])
      if KNSupportedTokenStorage.shared.isTokenSaved(token) {
        self.showErrorTopBannerMessage(with: "Fail", message: "Token is already added")
      } else {
        KNSupportedTokenStorage.shared.saveCustomToken(token)
        self.showSuccessTopBannerMessage(
          with: NSLocalizedString("success", value: "Success", comment: ""),
          message: NSLocalizedString("New token has been added successfully!", comment: ""),
          time: 1.0
        )
        self.navigationController.popViewController(animated: true)
      }
      
    }
  }
}

extension AddTokenCoordinator: QRCodeReaderDelegate {
  func readerDidCancel(_ reader: QRCodeReaderViewController!) {
    reader.dismiss(animated: true, completion: nil)
  }

  func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
    reader.dismiss(animated: true) {
      let address: String = {
        if result.count < 42 { return result }
        if result.starts(with: "0x") { return result }
        let string = "\(result.suffix(42))"
        if string.starts(with: "0x") { return string }
        return result
      }()
      self.rootViewController.coordinatorDidUpdateQRCode(address: address)
    }
  }
}
