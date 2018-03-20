// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KNConfirmTransactionViewControllerDelegate: class {
  func confirmTransactionDidConfirm(type: KNTransactionType)
  func confirmTransactionDidCancel()
}

class KNConfirmTransactionViewController: UIViewController {

  fileprivate let confirmTransactionCellID = "confirmTransactionCellID"
  fileprivate var transactionType: KNTransactionType

  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var contentTableView: UITableView!
  @IBOutlet weak var confirmButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!

  fileprivate var data: [(String, String)] = []

  fileprivate weak var delegate: KNConfirmTransactionViewControllerDelegate?

  init(delegate: KNConfirmTransactionViewControllerDelegate?, type: KNTransactionType) {
    self.delegate = delegate
    self.transactionType = type
    super.init(nibName: KNConfirmTransactionViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.createData()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
  }

  fileprivate func setupUI() {

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapToParentView(_:)))
    self.view.addGestureRecognizer(tapGesture)

    self.containerView.rounded(color: .clear, width: 0, radius: 10.0)
    self.containerView.backgroundColor = UIColor.white

    self.confirmButton.setTitle("Confirm".uppercased().toBeLocalised(), for: .normal)
    self.confirmButton.rounded(color: .clear, width: 0, radius: 5.0)
    self.cancelButton.setTitle("Cancel".uppercased().toBeLocalised(), for: .normal)
    self.cancelButton.rounded(color: .clear, width: 0, radius: 5.0)

    let nib = UINib(nibName: KNTransactionDetailsTableViewCell.className, bundle: nil)
    self.contentTableView.register(nib, forCellReuseIdentifier: confirmTransactionCellID)
    self.contentTableView.rowHeight = 60
    self.contentTableView.dataSource = self
    self.contentTableView.delegate = self
  }

  fileprivate func createData() {
    switch self.transactionType {
    case .exchange(let trans):
      // Amount Exchange & its USD Value
      let amountSpent = "\(trans.from.symbol)\(trans.displayAmount(short: false))".prefix(20)
      let usdValue = trans.usdValueStringForFromToken.prefix(16)
      // Amount received & Expected Rate
      let expectedReceive = "\(trans.to.symbol)\(trans.displayExpectedReceive(short: false))".prefix(20)
      let rate = "\(trans.from.symbol)/\(trans.to.symbol): \(trans.displayExpectedRate(short: false))".prefix(20)
      // Min Rate
      let minRate = trans.displayMinRate(short: false)?.prefix(20) ?? "--"
      // Est Fee & its USD Value
      let feeString = trans.displayFeeString(short: false).prefix(16)
      let usdFeeString = trans.usdValueStringForFee.prefix(16)

      self.data = [
        ("Amount Sent", "\(amountSpent)\n($\(usdValue))"),
        ("Expected Receive", "\(expectedReceive)\n\(rate)"),
        ("Min Rate", "\(trans.to.symbol)\(minRate)"),
        ("Est. Fee", "ETH\(feeString)\n($\(usdFeeString))"),
      ]
    case .transfer(let trans):
      let fromToken: KNToken = {
        switch trans.transferType {
        case .ether:
          return KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.isETH })!
        case .token(let object):
          return KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.address == object.contract })!
        }
      }()
      // Amount Transfer & its USD Value
      let amountSent = "\(fromToken.symbol)\(trans.value.fullString(decimals: fromToken.decimal))".prefix(20)
      let usdValue: String = {
        let rate = KNRateCoordinator.shared.usdRate(for: fromToken)?.rate ?? BigInt(0)
        return (rate * trans.value).shortString(units: .ether)
      }()
      // Transfer To Address
      let address = trans.to?.description ?? ""
      // Est Fee & its USD Value
      let (feeString, usdFeeString): (Substring, String) = {
        let gasPrice = trans.gasPrice ?? KNGasConfiguration.gasPriceDefault
        let gasLimit: BigInt = {
          if let limit = trans.gasLimit { return limit }
          return fromToken.isETH ? KNGasConfiguration.transferETHGasLimitDefault : KNGasConfiguration.transferTokenGasLimitDefault
        }()
        let fee = gasPrice * gasLimit
        let ethToken = KNJSONLoaderUtil.loadListSupportedTokensFromJSONFile().first(where: { $0.isETH })!
        let rate = KNRateCoordinator.shared.usdRate(for: ethToken)?.rate ?? BigInt(0)
        return (fee.fullString(units: .ether).prefix(16), (rate * fee).shortString(units: .ether))
      }()

      self.data = [
        ("Amount Sent", "\(amountSent)\n($\(usdValue))"),
        ("Transfer To", "\(address)"),
        ("Est. Fee", "ETH\(feeString)\n($\(usdFeeString))"),
      ]
    }
    self.contentTableView.reloadData()
  }

  func updateExpectedRateData(source: KNToken, dest: KNToken, amount: BigInt, expectedRate: BigInt) {
    if case .exchange(let transaction) = self.transactionType {
      if transaction.from == source && transaction.to == dest && transaction.amount == amount {
        let newTransaction = transaction.copy(expectedRate: expectedRate)
        self.transactionType = .exchange(newTransaction)
        self.createData()
      }
    }
  }

  @objc func didTapToParentView(_ sender: UITapGestureRecognizer) {
    let touchPoint = sender.location(in: self.view)
    if touchPoint.x < self.containerView.frame.minX || touchPoint.x > self.containerView.frame.maxX ||
      touchPoint.y < self.containerView.frame.minY || touchPoint.y > self.containerView.frame.maxY {
      self.delegate?.confirmTransactionDidCancel()
    }
  }

  @IBAction func cancelButtonPressed(_ sender: Any) {
    self.delegate?.confirmTransactionDidCancel()
  }

  @IBAction func confirmButtonPressed(_ sender: Any) {
    self.delegate?.confirmTransactionDidConfirm(type: self.transactionType)
  }
}

extension KNConfirmTransactionViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }
}

extension KNConfirmTransactionViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.data.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: confirmTransactionCellID, for: indexPath) as! KNTransactionDetailsTableViewCell
    let (field, value) = self.data[indexPath.row]
    cell.updateCell(text: field, details: value)
    return cell
  }
}
