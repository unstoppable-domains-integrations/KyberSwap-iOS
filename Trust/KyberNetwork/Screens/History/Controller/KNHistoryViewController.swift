// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNHistoryViewControllerDelegate: class {
  func historyViewControllerDidSelectTransaction(_ transaction: Transaction)
  func historyViewControllerDidClickExit()
}

class KNHistoryViewController: KNBaseViewController {

  fileprivate weak var delegate: KNHistoryViewControllerDelegate?

  fileprivate var transactions: [KNHistoryTransaction] = []

  init(delegate: KNHistoryViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNHistoryViewController.className, bundle: nil)
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
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "History".toBeLocalised()
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.historyViewControllerDidClickExit()
  }
}

extension KNHistoryViewController {
  func coordinatorUpdateHistoryTransactions(_ transactions: [KNHistoryTransaction]) {
    self.transactions = transactions
  }
}
