// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNFilterLimitOrderViewControllerDelegate: class {
  func filterLimitOrderViewController(_ controller: KNFilterLimitOrderViewController, apply pairs: [String]?, status: [Int])
}

class KNFilterLimitOrderViewModel {
  var pairs: [String]?
  var status: [Int] = [0]
  var isSortAsc: Bool = true {
    didSet { self.updateAllPairs(self.allPairs) }
  }

  var allPairs: [String] = []

  init(pairs: [String]?, status: [Int], allPairs: [String]) {
    self.pairs = pairs
    self.status = status
    self.allPairs = allPairs.sorted(by: {
      return $0 < $1 && self.isSortAsc
    })
  }

  func updateAllPairs(_ pairs: [String]) {
    self.allPairs = pairs.sorted(by: {
      if self.isSortAsc { return $0 < $1 }
      return $0 > $1
    })
  }
}

class KNFilterLimitOrderViewController: KNBaseViewController {

  let kFilterLimitOrderSelectPairTableViewCellID = "kFilterLimitOrderSelectPairTableViewCell"
  let kFilterLimitOrderSelectPairTableViewCellHeight: CGFloat = 36.0

  @IBOutlet weak var containerView: UIView!

  @IBOutlet var separatorViews: [UIView]!

  @IBOutlet weak var filterTextLabel: UILabel!
  @IBOutlet weak var pairTextLabel: UILabel!
  @IBOutlet weak var statusTextLabel: UILabel!

  @IBOutlet weak var sortPairAscButton: UIButton!
  @IBOutlet weak var sortPairDescButton: UIButton!

  @IBOutlet weak var listPairsTableView: UITableView!

  @IBOutlet weak var statusOpenButton: UIButton!
  @IBOutlet weak var statusFilledButton: UIButton!
  @IBOutlet weak var statusCanceledButton: UIButton!
  @IBOutlet weak var statusInProgressButton: UIButton!
  @IBOutlet weak var statusInvalidatedButton: UIButton!

  @IBOutlet weak var resetButton: UIButton!
  @IBOutlet weak var applyButton: UIButton!

  let viewModel: KNFilterLimitOrderViewModel
  weak var delegate: KNFilterLimitOrderViewControllerDelegate?

  init(viewModel: KNFilterLimitOrderViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KNFilterLimitOrderViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded(radius: 5.0)

    self.filterTextLabel.text = "Filter".toBeLocalised().uppercased()
    self.pairTextLabel.text = "Pair".toBeLocalised()
    self.statusTextLabel.text = "Status".toBeLocalised()

    self.resetButton.rounded(
      color: UIColor.Kyber.border,
      width: 1.0,
      radius: self.resetButton.frame.height / 2.0
    )
    self.resetButton.setTitle("Reset".toBeLocalised(), for: .normal)

    self.applyButton.rounded(radius: self.resetButton.frame.height / 2.0)
    self.applyButton.applyGradient()
    self.applyButton.setTitle("Apply".toBeLocalised(), for: .normal)

    let nib = UINib(nibName: KNFilterLimitOrderSelectPairTableViewCell.className, bundle: nil)
    self.listPairsTableView.register(
      nib,
      forCellReuseIdentifier: kFilterLimitOrderSelectPairTableViewCellID
    )
    self.listPairsTableView.backgroundColor = .clear
    self.listPairsTableView.rowHeight = kFilterLimitOrderSelectPairTableViewCellHeight
    self.listPairsTableView.dataSource = self

    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true

    self.updateSortPairView()
    self.updateStatusView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.separatorViews.forEach({ $0.removeSublayer(at: 0) })
    self.separatorViews.forEach({ $0.dashLine(width: 1.0, color: UIColor.Kyber.dashLine) })
  }

  fileprivate func updateSortPairView() {
    self.sortPairAscButton.rounded(
      color: self.viewModel.isSortAsc ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: self.viewModel.isSortAsc ? 6.0 : 1.0,
      radius: self.sortPairAscButton.frame.height / 2.0
    )
    self.sortPairDescButton.rounded(
      color: !self.viewModel.isSortAsc ? UIColor.Kyber.enygold : UIColor.Kyber.border,
      width: !self.viewModel.isSortAsc ? 6.0 : 1.0,
      radius: self.sortPairDescButton.frame.height / 2.0
    )
    self.listPairsTableView.reloadData()
  }

  fileprivate func updateStatusView() {
    self.statusOpenButton.rounded(
      color: self.viewModel.status.contains(0) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusOpenButton.setImage(
      self.viewModel.status.contains(0) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusInProgressButton.rounded(
      color: self.viewModel.status.contains(1) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusInProgressButton.setImage(
      self.viewModel.status.contains(1) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusFilledButton.rounded(
      color: self.viewModel.status.contains(2) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusFilledButton.setImage(
      self.viewModel.status.contains(2) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusCanceledButton.rounded(
      color: self.viewModel.status.contains(3) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusCanceledButton.setImage(
      self.viewModel.status.contains(3) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
    self.statusInvalidatedButton.rounded(
      color: self.viewModel.status.contains(4) ? UIColor.clear : UIColor.Kyber.border,
      width: 1.0,
      radius: 2.5
    )
    self.statusInvalidatedButton.setImage(
      self.viewModel.status.contains(4) ? UIImage(named: "check_box_icon") : nil,
      for: .normal
    )
  }

  func updateListPairs(_ pairs: [String], selectedPairs: [String]?, status: [Int]) {
    self.viewModel.updateAllPairs(pairs)
    self.viewModel.pairs = selectedPairs
    self.viewModel.status = status
    self.updateSortPairView()
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let touchPoint = sender.location(in: self.view)
    if touchPoint.x < self.containerView.frame.minX || touchPoint.x > self.containerView.frame.maxX
      || touchPoint.y < self.containerView.frame.minY || touchPoint.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  @IBAction func pairSortAscButtonPressed(_ sender: Any) {
    self.viewModel.isSortAsc = true
    self.updateSortPairView()
  }

  @IBAction func pairSortDescButtonPressed(_ sender: Any) {
    self.viewModel.isSortAsc = false
    self.updateSortPairView()
  }

  @IBAction func statusOpenButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 0) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(0)
    }
    self.updateStatusView()
  }

  @IBAction func statusInProgressButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 1) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(1)
    }
    self.updateStatusView()
  }

  @IBAction func statusFilledButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 2) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(2)
    }
    self.updateStatusView()
  }

  @IBAction func statusCancelledButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 3) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(3)
    }
    self.updateStatusView()
  }

  @IBAction func statusInvalidateButtonPressed(_ sender: Any) {
    if let id = self.viewModel.status.firstIndex(of: 4) {
      self.viewModel.status.remove(at: id)
    } else {
      self.viewModel.status.append(4)
    }
    self.updateStatusView()
  }

  @IBAction func resetButtonPressed(_ sender: Any) {
    self.viewModel.isSortAsc = true
    self.viewModel.pairs = nil
    self.viewModel.status = [0, 1]

    self.updateSortPairView()
    self.updateStatusView()
  }

  @IBAction func applyButtonPressed(_ sender: Any) {
    self.dismiss(animated: true) {
      self.delegate?.filterLimitOrderViewController(
        self,
        apply: self.viewModel.pairs,
        status: self.viewModel.status
      )
    }
  }
}

extension KNFilterLimitOrderViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return (self.viewModel.allPairs.count + 1) / 2
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: kFilterLimitOrderSelectPairTableViewCellID,
      for: indexPath
    ) as! KNFilterLimitOrderSelectPairTableViewCell
    let row = indexPath.row
    let firstPair = self.viewModel.allPairs[2 * row]
    let isFirstPairSelected: Bool = {
      if let pairs = self.viewModel.pairs {
        return pairs.contains(firstPair)
      }
      return true
    }()
    let secondPair: String = {
      if 2 * row + 1 < self.viewModel.allPairs.count {
        return self.viewModel.allPairs[2 * row + 1]
      }
      return ""
    }()
    let isSecondPairSelected: Bool = {
      if secondPair.isEmpty { return false }
      if let pairs = self.viewModel.pairs {
        return pairs.contains(secondPair)
      }
      return true
    }()
    cell.updateCell(
      firstPair: firstPair,
      isFirstPairSelected: isFirstPairSelected,
      secondPair: secondPair,
      isSecondPairSelected: isSecondPairSelected
    )
    cell.delegate = self
    return cell
  }
}

extension KNFilterLimitOrderViewController: KNFilterLimitOrderSelectPairTableViewCellDelegate {
  func filterLimitOrderSelectPairTableViewCell(_ cell: KNFilterLimitOrderSelectPairTableViewCell, didSelect pair: String) {
    var pairs: [String] = {
      if let pairs = self.viewModel.pairs { return pairs }
      return self.viewModel.allPairs
    }()
    if let index = pairs.firstIndex(of: pair) {
      pairs.remove(at: index)
    } else {
      pairs.append(pair)
    }
    if pairs.count == self.viewModel.allPairs.count {
      self.viewModel.pairs = nil // select all
    } else {
      self.viewModel.pairs = pairs
    }
    self.listPairsTableView.reloadData()
  }
}
