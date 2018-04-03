// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNWalletViewControllerDelegate: class {
  func walletViewControllerDidExit()
}

class KNWalletViewController: KNBaseViewController {

  fileprivate weak var delegate: KNWalletViewControllerDelegate?

  @IBOutlet weak var estimatedValueTextLabel: UILabel!
  @IBOutlet weak var estimatedBalanceAmountLabel: UILabel!

  @IBOutlet weak var smallAssetsTextLabel: UILabel!
  @IBOutlet weak var smallAssetsSwitch: UISwitch!

  @IBOutlet weak var tokensTableView: UITableView!

  init(delegate: KNWalletViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNWalletViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }

  fileprivate func setupUI() {
    self.setupNavigationBar()
  }

  fileprivate func setupNavigationBar() {
    self.navigationItem.title = "Wallet"
    self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Exit", style: .plain, target: self, action: #selector(self.exitButtonPressed(_:)))
    self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white
  }

  fileprivate func setupEstimatedTotalValue() {
    self.estimatedValueTextLabel.text = "Estimated Value".toBeLocalised()
    self.estimatedBalanceAmountLabel.text = "0 ETH\n0 USD"
  }

  fileprivate func setupSmallAssets() {
    self.smallAssetsTextLabel.text = "Small assets".toBeLocalised()
    self.smallAssetsSwitch.isOn = true
  }

  fileprivate func setupTokensTableView() {
    let nib = UINib(nibName: KNWalletTokenTableViewCell.className, bundle: nil)
    self.tokensTableView.register(nin, forCellReuseIdentifier: KNWalletTokenTableViewCell.cellID)
    self.tokensTableView.estimatedRowHeight = 80.0
    self.tokensTableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }
}

extension KNWalletViewController {
  @objc func exitButtonPressed(_ sender: Any) {
    self.delegate?.walletViewControllerDidExit()
  }
}
