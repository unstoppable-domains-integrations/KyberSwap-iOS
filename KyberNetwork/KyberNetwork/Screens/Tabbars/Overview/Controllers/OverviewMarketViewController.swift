//
//  OverviewMarketViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 2/17/21.
//

import UIKit

enum MarketOverviewSortingType {
  case token(dec: Bool)
  case price(dec: Bool)
  case change24(dec: Bool)
}

class OverviewMarketViewModel {
  var allData: [OverviewMarketCellViewModel] = []
  var dataSource: [OverviewMarketCellViewModel] = []
  var currencyType: CurrencyType = .usd
  var soringType: MarketOverviewSortingType = .token(dec: true)
  var isFaved: Bool = false
  
  init() {
    self.reloadAllData()
  }
  
  func reloadAllData() {
    self.allData.removeAll()
    let tokens = KNSupportedTokenStorage.shared.allTokens
    tokens.forEach { (token) in
      let price = KNTrackerRateStorage.shared.getPriceWithAddress(token.address) ?? TokenPrice(dictionary: [:])
      let favedStatus = KNSupportedTokenStorage.shared.getFavedStatusWithAddress(token.address)
      let viewModel = OverviewMarketCellViewModel(token: token, price: price, isFaved: favedStatus)
      self.allData.append(viewModel)
    }
    self.reloadDataSource()
  }
  
  func reloadDataSource() {
    var data = self.allData
    data.forEach { (viewModel) in
      viewModel.type = self.currencyType
    }
    data.sort { (left, right) -> Bool in
      switch self.soringType {
      case .token(let dec):
        return dec ? left.token.name < right.token.name : left.token.name > right.token.name
      case .price(let dec):
        return dec ? left.priceDouble < right.priceDouble : left.priceDouble > right.priceDouble
      case .change24(let dec):
        return dec ? left.change24Double < right.change24Double : left.change24Double > right.change24Double
      }
    }
    if self.isFaved {
      data = data.filter { (item) -> Bool in
        return item.isFaved
      }
    }
    
    self.dataSource = data
  }
  
  var displayFavoriteImage: UIImage? {
    return self.isFaved ? UIImage(named: "fav_overview_icon") : UIImage(named: "unFav_overview_icon")
  }
}

protocol OverviewMarketViewControllerDelegate: class {
  func overviewMarketViewController(_ controller: OverviewMarketViewController, didSelect token: Token)
}

class OverviewMarketViewController: KNBaseViewController, OverviewViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet var currencySelectButtons: [UIButton]!
  @IBOutlet weak var favouriteButton: UIButton!
  @IBOutlet var sortingSelectButtons: [UIButton]!
  @IBOutlet var sortingImageIndicator: [UIImageView]!
  @IBOutlet weak var usdButton: UIButton!
  @IBOutlet weak var ethButton: UIButton!
  
  weak var container: OverviewViewController?
  weak var delegate: OverviewMarketViewControllerDelegate?
  
  let viewModel: OverviewMarketViewModel = OverviewMarketViewModel()

  override func viewDidLoad() {
    super.viewDidLoad()

    let nib = UINib(nibName: OverviewMarketTableViewCell.className, bundle: nil)
    self.tableView.register(
      nib,
      forCellReuseIdentifier: OverviewMarketTableViewCell.kCellID
    )
    self.tableView.rowHeight = OverviewMarketTableViewCell.kCellHeight
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.reloadUI()
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

  @IBAction func favouriteButtonTapped(_ sender: UIButton) {
    self.viewModel.isFaved = !self.viewModel.isFaved
    self.favouriteButton.setImage(self.viewModel.displayFavoriteImage, for: .normal)
    self.viewModel.reloadDataSource()
    self.tableView.reloadData()
  }
  
  @IBAction func sortingButtonTapped(_ sender: UIButton) {
    self.sortingImageIndicator.forEach { (imageView) in
      if imageView.tag == sender.tag {
        if sender.tag == 1 {
          if case let .token(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .token(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .token(dec: true)
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
          if case let .change24(dec) = self.viewModel.soringType {
            self.viewModel.soringType = .change24(dec: !dec)
            self.updateUIForIndicatorView(imageView: imageView, dec: !dec)
          } else {
            self.viewModel.soringType = .change24(dec: true)
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
  }
}

extension OverviewMarketViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: OverviewMarketTableViewCell.kCellID,
      for: indexPath
    ) as! OverviewMarketTableViewCell
    
    let viewModel = self.viewModel.dataSource[indexPath.row]
    cell.updateCell(viewModel: viewModel)
    
    return cell
  }
}

extension OverviewMarketViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let viewModel = self.viewModel.dataSource[indexPath.row]
    self.delegate?.overviewMarketViewController(self, didSelect: viewModel.token)
  }
}

