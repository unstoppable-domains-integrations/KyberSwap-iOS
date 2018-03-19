// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIViewController {

  func showInsufficientBalanceAlert() {
    let alertController: UIAlertController = {
      let alert = UIAlertController(title: "Insufficient Balance", message: "You don't have enough balance to make the transaction!", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      return alert
    }()
    self.present(alertController, animated: true, completion: nil)
  }

  func showInvalidDataToMakeTransactionAlert() {
    let alertController = UIAlertController(title: nil, message: "Invalid data to make the transaction", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
    self.present(alertController, animated: true, completion: nil)
  }
}
