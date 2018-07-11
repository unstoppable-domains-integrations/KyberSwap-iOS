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

  init(token: TokenObject) {
    self.token = token
    self.data = []
  }

  var navigationTitle: String {
    return "(WIP) \(self.token.symbol) Price"
  }

  var rateAttributedString: NSAttributedString {
    let rateString: String = {
      if let double = KNTrackerRateStorage.shared.trackerRate(for: self.token)?.rateETHNow {
        let rate = BigInt(double * Double(EthereumUnit.ether.rawValue))
        return String(rate.string(units: .ether, minFractionDigits: 9, maxFractionDigits: 9).prefix(10))
      }
      return "---"
    }()
    let eth: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "141927"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12, weight: .medium),
    ]
    let rate: [NSAttributedStringKey: Any] = [
      NSAttributedStringKey.foregroundColor: UIColor(hex: "0d0d0d"),
      NSAttributedStringKey.font: UIFont.systemFont(ofSize: 32, weight: .regular),
    ]
    let attributedString = NSMutableAttributedString()
    attributedString.append(NSAttributedString(string: "ETH ", attributes: eth))
    attributedString.append(NSAttributedString(string: rateString, attributes: rate))
    return attributedString
  }

  func updateType(_ newType: KNTokenChartType) {
    self.type = newType
    self.data = []
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
    series.color = UIColor(hex: "31cb9e")
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

  @IBOutlet weak var navigationLabel: UILabel!
  @IBOutlet weak var ethRateLabel: UILabel!
  @IBOutlet weak var changePercentLabel: UILabel!
  @IBOutlet weak var priceChart: Chart!

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
    self.startTimer()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.stopTimer()
  }

  fileprivate func setupUI() {
    self.navigationLabel.text = self.viewModel.navigationTitle
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString

    self.changePercentLabel.isHidden = true
    self.touchPriceLabel.isHidden = true

//    self.priceChart.delegate = self
    self.reloadViewDataDidUpdate()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.tokenChartViewController(self, run: .back)
  }

  @IBAction func actionButtonDidPress(_ sender: UISegmentedControl) {
    if sender.selectedSegmentIndex == 0 {
      self.delegate?.tokenChartViewController(self, run: .buy(token: self.viewModel.token))
    } else if sender.selectedSegmentIndex == 1 {
      self.delegate?.tokenChartViewController(self, run: .sell(token: self.viewModel.token))
    } else {
      self.delegate?.tokenChartViewController(self, run: .send(token: self.viewModel.token))
    }
    sender.selectedSegmentIndex = -1
  }

  @IBAction func dataTypeDidChange(_ sender: UISegmentedControl) {
    let type = KNTokenChartType(rawValue: sender.selectedSegmentIndex) ?? .day
    self.touchPriceLabel.isHidden = true
    self.viewModel.updateType(type)
    self.reloadViewDataDidUpdate()
    self.startTimer()
  }

  @IBAction func screenEdgePanGestureAction(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.tokenChartViewController(self, run: .back)
    }
  }

  fileprivate func shouldUpdateData(for type: KNTokenChartType, token: TokenObject) {
    self.viewModel.fetchNewData(
      for: self.viewModel.token,
      type: self.viewModel.type) { [weak self] result in
        switch result {
        case .success(let isSuccess):
          if isSuccess {
            self?.reloadViewDataDidUpdate()
          }
        case .failure(let error):
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
    self.priceChart.removeAllSeries()
    self.priceChart.add(self.viewModel.displayDataSeries)
    self.priceChart.xLabels = []
  }

  func coordinatorUpdateETHRate() {
    self.ethRateLabel.attributedText = self.viewModel.rateAttributedString
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
