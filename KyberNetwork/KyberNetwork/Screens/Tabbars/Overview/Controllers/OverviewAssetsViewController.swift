//
//  OverviewAssetsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit
import BigInt

enum AssetsOverviewSortingType {
  case balance(dec: Bool)
  case price(dec: Bool)
  case value(dec: Bool)
}

class OverviewAssetsViewModel {
  var data: [OverviewAssetsCellViewModel] = []
  var dataSource: [OverviewAssetsCellViewModel] = []
  var currencyType: CurrencyType = .usd
  var soringType: AssetsOverviewSortingType = .balance(dec: true)
  
  init() {
    self.reloadAllData()
  }
  
  func reloadAllData() {
    self.data.removeAll()
    let tokens = KNSupportedTokenStorage.shared.allTokens
    tokens.forEach { (token) in
      guard let balance = BalanceStorage.shared.balanceForAddress(token.address), balance.balance != "0" else {
        return
      }
      let price = KNTrackerRateStorage.shared.getPriceWithAddress(token.address) ?? TokenPrice(dictionary: [:])
      let viewModel = OverviewAssetsCellViewModel(token: token, price: price, balance: balance)
      self.data.append(viewModel)
    }
    self.reloadDataSource()
  }

  func reloadDataSource() {
    let cache = self.data
    cache.forEach { (viewModel) in
      viewModel.currencyType = self.currencyType
    }
    
    data.sort { (left, right) -> Bool in
      switch self.soringType {
      case .balance(let dec):
        return dec ? left.balanceBigInt < right.balanceBigInt : left.balanceBigInt > right.balanceBigInt
      case .price(let dec):
        return dec ? left.priceDouble < right.priceDouble : left.priceDouble > right.priceDouble
      case .value(let dec):
        return dec ? left.valueBigInt < right.valueBigInt : left.valueBigInt > right.valueBigInt
      }
    }
    
    self.dataSource = cache
  }
  
  var totalValueBigInt: BigInt {
    var total = BigInt(0)
    self.dataSource.forEach { (viewModel) in
      total += (viewModel.valueBigInt * BigInt(10).power(18) / BigInt(10).power(viewModel.token.decimals))
    }
    return total
  }
  
  var totalValueString: String {
    let totalString = self.totalValueBigInt.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 6)
    return self.currencyType == .usd ? "$" + totalString : totalString
  }
}

class OverviewAssetsViewController: KNBaseViewController, OverviewViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var currencySelectButtons: [UIButton]!
  @IBOutlet var sortingImageIndicator: [UIImageView]!
  @IBOutlet weak var totalStringLabel: UILabel!
  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var ethButton: UIButton!
  
  
  weak var container: OverviewViewController?

  let viewModel = OverviewAssetsViewModel()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: OverviewAssetsTableViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewAssetsTableViewCell.kCellID
    )
    self.tableView.rowHeight = OverviewAssetsTableViewCell.kCellHeight
    self.updateUITotalValue()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.reloadUI()
  }
  
  fileprivate func updateUITotalValue() {
    self.totalStringLabel.text = self.viewModel.totalValueString
  }
  
  fileprivate func reloadUI() {
    guard self.isViewLoaded else {
      return
    }
    switch self.viewModel.currencyType {
    case .usd:
      self.usdButton.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
      self.ethButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
    case .eth:
      self.usdButton.setTitleColor(UIColor.Kyber.SWWhiteTextColor, for: .normal)
      self.ethButton.setTitleColor(UIColor.Kyber.SWYellow, for: .normal)
    }
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
    self.updateUITotalValue()
  }
  
  @IBAction func currencyTypeButtonTapped(_ sender: UIButton) {
    if sender.tag == 1 {
      self.viewModel.currencyType = .usd
    } else {
      self.viewModel.currencyType = .eth
    }
    self.reloadUI()
    self.container?.viewControllerDidChangeCurrencyType(self, type: self.viewModel.currencyType)
  }

  @IBAction func sortingButtonTapped(_ sender: UIButton) {
    self.sortingImageIndicator.forEach { (imageView) in
      if imageView.tag == sender.tag {
        if sender.tag == 1 {
          if case let .balance(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .balance(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .balance(dec: true)
            self.updateUIForIndicatorView(imageView: imageView, dec: true)
          }
        } else if sender.tag == 2 {
          if case let .price(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .price(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .price(dec: true)
            self.updateUIForIndicatorView(imageView: imageView, dec: true)
          }
        } else if sender.tag == 3 {
          if case let .value(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .value(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .value(dec: true)
            self.updateUIForIndicatorView(imageView: imageView, dec: true)
          }
        }
      } else {
        imageView.image = UIImage(named: "no_arrow_overview_icon")
      }
    }
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
  }
  
  fileprivate func updateUIForIndicatorView(imageView: UIImageView, dec: Bool) {
    if dec {
      imageView.image = UIImage(named: "down_arrow_overview_icon")
    } else {
      imageView.image = UIImage(named: "up_arrow_overview_icon")
    }
  }
  
  func viewControllerDidChangeCurrencyType(_ controller: OverviewViewController, type: CurrencyType) {
    guard type != self.viewModel.currencyType else {
      return
    }
    self.viewModel.currencyType = type
    self.reloadUI()
  }
  
  func coordinatorDidUpdateDidUpdateTokenList() {
    guard self.isViewLoaded else { return }
    self.viewModel.reloadAllData()
    self.reloadUI()
    self.updateUITotalValue()
  }
}

extension OverviewAssetsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewAssetsTableViewCell.kCellID,
      for: indexPath
    ) as! OverviewAssetsTableViewCell
    
    cell.updateCell(viewModel: self.viewModel.dataSource[indexPath.row])
    
    return cell
  }
}
