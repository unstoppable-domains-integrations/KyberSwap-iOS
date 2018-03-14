// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNExchangeTokenViewControllerDelegate: class {
}

class KNExchangeTokenViewController: UIViewController {

  fileprivate weak var delegate: KNExchangeTokenViewControllerDelegate?

  init(delegate: KNExchangeTokenViewControllerDelegate?) {
    self.delegate = delegate
    super.init(nibName: KNExchangeTokenViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    NSLog("Did open: \(self.className)")
  }

  func updateBalance(usd: BigInt, eth: BigInt) {
    self.navigationItem.title = "\(EtherNumberFormatter.short.string(from: usd)) USD (\(EtherNumberFormatter.short.string(from: eth, units: EthereumUnit.ether)) ETH)"
  }
}
