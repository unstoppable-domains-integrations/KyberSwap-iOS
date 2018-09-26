// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Result
import BigInt
import SwiftChart

enum KNTokenChartType: Int {
  case day = 0
  case week = 1
  case month = 2
  case year = 3
  case all = 4

  var resolution: String {
    switch self {
    case .day: return "15"
    case .week: return "60"
    case .month: return "360"
    case .year: return "D"
    case .all: return "W"
    }
  }

  func fromTime(for toTime: Int64) -> Int64 {
    switch self {
    case .day:
      return toTime - 24 * 60 * 60
    case .week:
      return toTime - 7 * 24 * 60 * 60
    case .month:
      return toTime - 30 * 24 * 60 * 60
    case .year:
      return toTime - 365 * 24 * 60 * 60
    case .all:
      return 1
    }
  }

  var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    switch self {
    case .day:
      formatter.dateFormat = "HH:mm"
    case .week, .month:
      formatter.dateFormat = "dd/MM HH:MM"
    case .year, .all:
      formatter.dateFormat = "dd/MM"
    }
    return formatter
  }

  func label(for time: Double) -> String {
    let date = Date(timeIntervalSince1970: time)
    return self.dateFormatter.string(from: date)
  }
}

enum KNTokenChartViewEvent {
  case back
  case buy(token: TokenObject)
  case sell(token: TokenObject)
  case send(token: TokenObject)
}

protocol KNTokenChartViewControllerDelegate: class {
  func tokenChartViewController(_ controller: KNTokenChartViewController, run event: KNTokenChartViewEvent)
}

class KNTokenChartViewModel {
  let token: TokenObject
  var type: KNTokenChartType = .day
  var data: [KNChartObject] = []
  var balance: Balance = Balance(value: BigInt())

  init(token: TokenObject) {
    self.token = token
    self.data = []
  }

  var navigationTitle: String {
    return "\(self.token.symbol)"
  }

  var isTokenSupported: Bool { return self.token.isSupported }

  var rateAttributedString: NSAttributedString {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else {
      return NSMutableAttributedString()
    }
    let rateString: String = {
      let rate = BigInt(trackerRate.rateETHNow * Double(EthereumUnit.ether.rawValue))
      return String(rate.string(units: .ether, minFractionDigits: 9, maxFractionDigits: 9).prefix(12))
    }()
    let change24hString: String = {
      return String("\(trackerRate.changeETH24h)".prefix(5)) + "%"
    }()
    let changeColor: UIColor = {
      if trackerRate.changeETH24h == 0.0 { return UIColor.Kyber.grayChateau }
      return trackerRate.changeETH24h > 0 ? UIColor.Kyber.shamrock : UIColor.Kyber.strawberry
    }()
    let rateAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 131, green: 136, blue: 148),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 22),
    ]
    let changeAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: changeColor,
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 16),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "ETH \(rateString) ", attributes: rateAttributes))
    attributedString.append(NSAttributedString(string: "\n\(change24hString)", attributes: changeAttributes))
    return attributedString
  }

  var balanceAttributedString: NSAttributedString {
    let balance: String = self.balance.value.string(
      decimals: self.token.decimals,
      minFractionDigits: 0,
      maxFractionDigits: min(self.token.decimals, 6)
    )
    let balanceAttributes: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(red: 46, green: 57, blue: 87),
      NSAttributedStringKey.font: UIFont.Kyber.medium(with: 18),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: balance, attributes: balanceAttributes))
    return attributedString
  }

  var totalValueString: String {
    guard let trackerRate = KNTrackerRateStorage.shared.trackerRate(for: self.token) else { return "" }
    let value: BigInt = {
      return trackerRate.rateETHBigInt * self.balance.value / BigInt(10).power(self.token.decimals)
    }()
    let valueString: String = value.string(units: .ether, minFractionDigits: 0, maxFractionDigits: 9)
    return "~\(valueString.prefix(12)) ETH"
  }

  func updateType(_ newType: KNTokenChartType) {
    self.type = newType
    self.data = []
  }

  func updateBalance(_ balance: Balance) {
    self.balance = balance
  }

  func updateData(_ newData: JSONDictionary, symbol: String, resolution: String) {
    let objects: [KNChartObject] = KNChartObject.objects(
      from: newData,
      symbol: symbol,
      resolution: resolution
    )
    if self.token.symbol == symbol && self.type.resolution == resolution {
      self.data.append(contentsOf: objects)
      self.data = self.data.sorted(by: { $0.time < $1.time })
    }
  }

  var displayDataSeries: ChartSeries {
    if let object = self.data.first {
      self.data = self.data.filter({ $0.time >= self.type.fromTime(for: object.time) })
    }
    guard let first = self.data.first else {
      return ChartSeries(data: [(x: 0, y: 0)])
    }
    let data = self.data.map {
      return (x: Double($0.time - first.time) / (15.0 * 60.0), y: $0.close)
    }
    let series = ChartSeries(data: data)
    series.color = UIColor.Kyber.blueGreen
    series.area = true
    return series
  }

  var xDoubleLabels: [Double] {
    guard let first = self.data.first else {
      return []
    }
    let data = self.data.map { return Double($0.time - first.time) / (15.0 * 60.0) }
    return data
  }

  var yDoubleLables: [Double] {
    if self.data.isEmpty { return [] }
    var minDouble: Double = self.data.first!.close
    var maxDouble: Double = self.data.first!.close
    self.data.forEach({
      minDouble = min(minDouble, $0.close)
      maxDouble = max(maxDouble, $0.close)
    })
    return [minDouble, maxDouble]
  }

  func fetchNewData(for token: TokenObject, type: KNTokenChartType, completion: @escaping ((Result<Bool, AnyError>) -> Void)) {
    let to: Int64 = Int64(floor(Date().timeIntervalSince1970))
    let from: Int64 = {
      let fromTime: Int64 = type.fromTime(for: to)
      if let time = self.data.first?.time {
        return max(time + 60, fromTime)
      }
      return fromTime
    }()
    let provider = MoyaProvider<KNTrackerService>()
    let service = KNTrackerService.getChartHistory(
      symbol: token.symbol,
      resolution: type.resolution,
      from: from,
      to: to,
      rateType: "mid"
    )
    print("------ Chart history: Fetching for \(token.symbol) resolution \(type.resolution) ------")
    DispatchQueue.global(qos: .background).async {
      provider.request(service) { response in
        DispatchQueue.main.async {
          switch response {
          case .success(let result):
            do {
              if let data = try result.mapJSON(failsOnEmptyData: false) as? JSONDictionary {
                self.updateData(data, symbol: token.symbol, resolution: type.resolution)
                print("------ Chart history: Successfully load data for \(token.symbol) resolution \(type.resolution) ------")
                completion(.success(true))
              } else {
                print("------ Chart history: Failed parse data for \(token.symbol) resolution \(type.resolution) ------")
                completion(.success(false))
              }
            } catch let error {
              print("------ Chart history: Failed map JSON data for \(token.symbol) resolution \(type.resolution) error \(error.prettyError)------")
              completion(.failure(AnyError(error)))
            }
          case .failure(let error):
            print("------ Chart history: Successfully load data for \(token.symbol) resolution \(type.resolution) error \(error.prettyError) ------")
            completion(.failure(AnyError(error)))
          }
        }
      }
    }
  }
}

class KNTokenChartViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navigationLabel: UILabel!
  @IBOutlet weak var symbolLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!

  @IBOutlet weak var ethRateLabel: UILabel!
  @IBOutlet weak var balanceLabel: UILabel!
  @IBOutlet weak var totalValueLabel: UILabel!

  @IBOutlet weak var priceChart: Chart!
  @IBOutlet weak var noDataLabel: UILabel!
  @IBOutlet weak var iconImageView: UIImageView!
  @IBOutlet weak var buyButton: UIButton!
  @IBOutlet weak var sellButton: UIButton!
  @IBOutlet weak var sendButton: UIButton!

  @IBOutlet weak var dataTypeButtonContainerView: UIView!
  @IBOutlet var dataTypeButtons: [UIButton]!

  weak var delegate: KNTokenChartViewControllerDelegate?
  fileprivate var viewModel: KNTokenChartViewModel

  fileprivate var timer: Timer?
  @IBOutlet weak var touchPriceLabel: UILabel!
  @IBOutlet weak var leftPaddingForTouchPriceLabelConstraint: NSLayoutConstraint!

  init(viewModel: KNTokenChartViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNTokenChartViewController.className, bundle: nil)
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
    if self.viewModel.isTokenSupported {
      self.startTimer()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if self.viewModel.isTokenSupported {
      self.stopTimer()
    }
  }

  fileprivate func setupUI() {

    let style = KNAppStyleType.current
    self.view.backgroundColor = style.chartBackgroundColor
    self.headerContainerView.backgroundColor = style.chartHeaderBackgroundColor

    self.iconImageView.setTokenImage(
      token: self.viewModel.token,
      size: self.iconImageView.frame.size
    )
    self.navigationLabel.text = self.viewModel.navigationTitle
    self.symbolLabel.text = self.viewModel.token.symbol
    self.nameLabel.text = self.viewModel.token.name

    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    self.ethRateLabel.textAlignment = .center
    self.ethRateLabel.numberOfLines = 0

    self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
    self.totalValueLabel.text = self.viewModel.totalValueString

    self.touchPriceLabel.isHidden = true

//    self.priceChart.delegate = self
    self.noDataLabel.isHidden = false

    self.priceChart.isHidden = true
    self.priceChart.labelColor = UIColor.Kyber.mirage
    self.priceChart.labelFont = UIFont.Kyber.medium(with: 12)

    self.sendButton.rounded(
      color: .clear,
      width: 1,
      radius: style.buttonRadius(for: self.sendButton.frame.height)
    )
    self.sendButton.backgroundColor = UIColor.Kyber.merigold
    self.sendButton.setTitle(
      style.buttonTitle(with: "Send".toBeLocalised()),
      for: .normal
    )
    self.buyButton.rounded(
      color: .clear,
      width: 1,
      radius: style.buttonRadius(for: self.buyButton.frame.height)
    )
    self.buyButton.backgroundColor = UIColor.Kyber.shamrock
    self.buyButton.setTitle(
      style.buttonTitle(with: "Buy".toBeLocalised()),
      for: .normal
    )
    self.sellButton.rounded(
      color: .clear,
      width: 1,
      radius: style.buttonRadius(for: self.sellButton.frame.height)
    )
    self.sellButton.backgroundColor = UIColor.Kyber.blueGreen
    self.sellButton.setTitle(
      style.buttonTitle(with: "Sell".toBeLocalised()),
      for: .normal
    )

    if self.viewModel.isTokenSupported {
      self.noDataLabel.text = "Updating data ...".toBeLocalised()
      self.updateDisplayDataType(.day)
    } else {
      self.dataTypeButtonContainerView.isHidden = true
      self.noDataLabel.text = "This token is not supported by Kyber Network".toBeLocalised()
      self.buyButton.isHidden = true
      self.sellButton.setTitle(
        style.buttonTitle(with: "Send".toBeLocalised()),
        for: .normal
      )
      self.sellButton.backgroundColor = UIColor.Kyber.merigold
      self.sendButton.isHidden = true
    }
  }

  fileprivate func updateDisplayDataType(_ type: KNTokenChartType) {
    self.viewModel.updateType(type)
    self.touchPriceLabel.isHidden = true
    for button in self.dataTypeButtons {
      button.rounded(
        color: button.tag == type.rawValue ? UIColor.Kyber.shamrock : UIColor.clear,
        width: 2,
        radius: 4.0
      )
    }
    self.reloadViewDataDidUpdate()
    self.startTimer()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.tokenChartViewController(self, run: .back)
  }

  @IBAction func actionButtonDidPress(_ sender: UIButton) {
    if !self.viewModel.isTokenSupported {
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
      return
    }
    if sender.tag == 0 {
      self.delegate?.tokenChartViewController(self, run: .buy(token: self.viewModel.token))
    } else if sender.tag == 1 {
      self.delegate?.tokenChartViewController(self, run: .sell(token: self.viewModel.token))
    } else {
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
    }
  }

  @IBAction func dataTypeDidChange(_ sender: UIButton) {
    let type = KNTokenChartType(rawValue: sender.tag) ?? .day
    self.updateDisplayDataType(type)
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.tokenChartViewController(self, run: .back)
    }
  }

  fileprivate func shouldUpdateData(for type: KNTokenChartType, token: TokenObject) {
    self.noDataLabel.text = "Updating data ...".toBeLocalised()
    self.viewModel.fetchNewData(
      for: self.viewModel.token,
      type: self.viewModel.type) { [weak self] result in
        switch result {
        case .success(let isSuccess):
          if isSuccess {
            self?.reloadViewDataDidUpdate()
          } else {
            self?.noDataLabel.text = "Can not update data".toBeLocalised()
          }
        case .failure(let error):
          self?.noDataLabel.text = "Can not update data".toBeLocalised()
          self?.displayError(error: error)
        }
    }
  }

  fileprivate func startTimer() {
    self.timer?.invalidate()
    // Immediately call fetch data
    self.shouldUpdateData(for: self.viewModel.type, token: self.viewModel.token)
    self.timer = Timer.scheduledTimer(
      withTimeInterval: 60,
      repeats: true, block: { [weak self] _ in
        guard let `self` = self else { return }
        self.shouldUpdateData(for: self.viewModel.type, token: self.viewModel.token)
    })
  }

  fileprivate func stopTimer() {
    self.timer?.invalidate()
  }

  fileprivate func reloadViewDataDidUpdate() {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
    if self.viewModel.data.isEmpty {
      self.noDataLabel.text = "There is no data for this token".toBeLocalised()
      self.noDataLabel.isHidden = false
      self.priceChart.isHidden = true
    } else {
      self.noDataLabel.isHidden = true
      self.priceChart.isHidden = false
      self.priceChart.removeAllSeries()
      self.priceChart.add(self.viewModel.displayDataSeries)
      self.priceChart.yLabels = self.viewModel.yDoubleLables
      let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = min(9, self.viewModel.token.decimals)
        formatter.minimumFractionDigits = 2
        formatter.minimumIntegerDigits = 1
        return formatter
      }()
      self.priceChart.yLabelsFormatter = { (_, value) in
        return numberFormatter.string(from: NSNumber(value: value)) ?? ""
      }
      self.priceChart.xLabels = []
    }
  }

  func coordinatorUpdateETHRate() {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
  }

  func coordinatorUpdateBalance(balance: [String: Balance]) {
    if let bal = balance[self.viewModel.token.contract] {
      self.viewModel.updateBalance(bal)
      self.balanceLabel.attributedText = self.viewModel.balanceAttributedString
      self.totalValueLabel.text = self.viewModel.totalValueString
    }
  }
}

extension KNTokenChartViewController: ChartDelegate {
  func didFinishTouchingChart(_ chart: Chart) {
  }

  func didEndTouchingChart(_ chart: Chart) {
  }

  func didTouchChart(_ chart: Chart, indexes: [Int?], x: Double, left: CGFloat) {
    for (seriesId, dataId) in indexes.enumerated() {
      if let id = dataId, let value = chart.valueForSeries(seriesId, atIndex: id) {
        self.touchPriceLabel.text = String("\(value)".prefix(10))
        self.touchPriceLabel.isHidden = false
        self.leftPaddingForTouchPriceLabelConstraint.constant = left
        self.view.layoutIfNeeded()
      }
    }
  }
}
