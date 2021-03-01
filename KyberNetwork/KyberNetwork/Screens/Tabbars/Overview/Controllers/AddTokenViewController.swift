//
//  AddTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/1/21.
//

import UIKit

enum AddTokenViewEvent {
  case openQR
  case done(address: String, symbol: String, decimals: Int)
}

protocol AddTokenViewControllerDelegate: class {
  func addTokenViewController(_ controller: AddTokenViewController, run event: AddTokenViewEvent)
}

class AddTokenViewController: KNBaseViewController {
  @IBOutlet weak var addressField: UITextField!
  @IBOutlet weak var symbolField: UITextField!
  @IBOutlet weak var decimalsField: UITextField!
  @IBOutlet weak var doneButton: UIButton!
  weak var delegate: AddTokenViewControllerDelegate?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.doneButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.doneButton.removeSublayer(at: 0)
    self.doneButton.applyHorizontalGradient(with: UIColor.Kyber.SWButtonColors)
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.addressField.text = string
    }
  }

  @IBAction func qrButtonTapped(_ sender: UIButton) {
    self.delegate?.addTokenViewController(self, run: .openQR)
  }
  
  @IBAction func doneButtonTapped(_ sender: UIButton) {
    guard self.validateFields() else {
      return
    }
    self.delegate?.addTokenViewController(self, run: .done(address: self.addressField.text ?? "", symbol: self.symbolField.text ?? "", decimals: Int(self.decimalsField.text ?? "") ?? 6))
  }
  
  fileprivate func validateFields() -> Bool {
    if let text = self.addressField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Address is empty")
      return false
    }
    if let text = self.symbolField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Symbol is empty")
      return false
    }
    if let text = self.decimalsField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Decimals is empty")
      return false
    }
    return true
  }
  
  func coordinatorDidUpdateQRCode(address: String) {
    self.addressField.text = address
  }
}


