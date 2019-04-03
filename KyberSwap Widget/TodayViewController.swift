// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
  @IBOutlet weak var tokenDataTableView: UITableView!
  @IBOutlet weak var messageLabel: UILabel!

  fileprivate var dataArr: [[String: Any]] = []
  fileprivate var isExpanded: Bool = false

  fileprivate var timer: Timer?

  fileprivate let showMoreCount: Int = 12
  fileprivate let showLessCount: Int = 3
  fileprivate let tableHeight: CGFloat = 36.0

  deinit {
    self.timer?.invalidate()
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view from its nib.
    self.extensionContext?.widgetLargestAvailableDisplayMode = .expanded
    self.messageLabel.text = "Updating data..."
    self.messageLabel.isHidden = false
    self.tokenDataTableView.isHidden = true

    let nib = UINib(nibName: "TokenTableViewCell", bundle: nil)
    self.tokenDataTableView.register(nib, forCellReuseIdentifier: "TodayExtensionCellID")
    self.tokenDataTableView.rowHeight = tableHeight
    self.tokenDataTableView.delegate = self
    self.tokenDataTableView.dataSource = self

    self.reloadData(nil)
    self.timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { [weak self] _ in
      self?.reloadData(nil)
    })
  }
        
  func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
    self.reloadData(nil, completionHandler: completionHandler)
  }

  @objc func reloadData(_ sender: Any?, completionHandler: ((NCUpdateResult) -> Void)? = nil) {
    guard let url = URL(string: "https://api.kyber.network/change24h") else {
      self.updateViewWithData(self.dataArr)
      completionHandler?(NCUpdateResult.newData)
      return
    }
    let task = URLSession.shared.dataTask(with: url) { (data, resp, error) in
      DispatchQueue.main.async {
        guard error == nil else {
          self.updateViewWhenError()
          completionHandler?(NCUpdateResult.failed)
          return
        }
        guard let data = data else {
          self.updateViewWithData(self.dataArr)
          completionHandler?(NCUpdateResult.newData)
          return
        }
        do {
          let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
          var jsonArr: [[String: Any]] = []
          for (_, value) in jsonResponse {
            jsonArr.append(value as? [String: Any] ?? [:])
          }
          self.updateViewWithData(jsonArr)
          completionHandler?(NCUpdateResult.newData)
        } catch {
          self.updateViewWithData(self.dataArr)
          completionHandler?(NCUpdateResult.newData)
        }
      }
    }
    task.resume()
  }

  fileprivate func updateViewWithNoData() {
    self.messageLabel.text = "No data to show right now"
    self.messageLabel.isHidden = false
    self.tokenDataTableView.isHidden = true
  }

  fileprivate func updateViewWhenError() {
    self.messageLabel.text = "Can not load data, please try again later"
    self.messageLabel.isHidden = false
    self.tokenDataTableView.isHidden = true
  }

  fileprivate func updateViewWithData(_ data: [[String: Any]]) {
    self.dataArr = data.sorted(by: { (data0, data1) -> Bool in
      let symbol = data0["token_symbol"] as? String ?? ""
      if symbol == "ETH" || symbol == "KNC" || symbol == "WBTC" { return true }
      return false
    })
    if data.isEmpty {
      self.updateViewWithNoData()
      return
    }
    self.messageLabel.isHidden = true
    self.tokenDataTableView.isHidden = false
    self.tokenDataTableView.reloadData()
  }

  func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
    // 12px for top padding
    if activeDisplayMode == .compact {
      self.preferredContentSize = CGSize(width: maxSize.width, height: 12.0 + CGFloat(showLessCount) * tableHeight)
      self.isExpanded = false
    } else if activeDisplayMode == .expanded {
      self.preferredContentSize = CGSize(width: maxSize.width, height: 12.0 + CGFloat(showMoreCount) * tableHeight)
      self.isExpanded = true
    }
    self.tokenDataTableView.reloadData()
  }
}

extension TodayViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let symbol = self.dataArr[indexPath.row]["token_symbol"] as? String ?? ""
    guard let url = URL(string: "kyberswap://widget_open=true&symbol=\(symbol)") else { return }
    self.extensionContext?.open(url, completionHandler: nil)
  }
}

extension TodayViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let maxCount = self.isExpanded ? showMoreCount : showLessCount
    return min(maxCount, self.dataArr.count)
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "TodayExtensionCellID", for: indexPath) as! TokenTableViewCell
    let data = self.dataArr[indexPath.row]
    cell.updateCell(with: data)
    return cell
  }
}
