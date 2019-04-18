// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNEligibleTokensViewController: KNBaseViewController {

  fileprivate let tokensTableViewCellID: String = "tokensTableViewCellID"
  @IBOutlet weak var containerView: UIView!
  @IBOutlet weak var containerViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var eligibleTextLabel: UILabel!
  @IBOutlet weak var separatorView: UIView!
  @IBOutlet weak var eligibleTokensTableView: UITableView!

  fileprivate let eligibleTokens: [String]
  init(data: String) {
    let eligibleTokens = data.components(separatedBy: ",").filter({ return !$0.isEmpty })
    self.eligibleTokens = eligibleTokens.sorted(by: { return $0 < $1 })
    super.init(nibName: KNEligibleTokensViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.containerView.rounded(radius: 5.0)

    self.eligibleTextLabel.text = NSLocalizedString("Eligible Tokens", comment: "")
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    let nib = UINib(nibName: KNEligibleTokensTableViewCell.className, bundle: nil)
    self.eligibleTokensTableView.register(nib, forCellReuseIdentifier: tokensTableViewCellID)
    self.eligibleTokensTableView.rowHeight = 44.0
    self.containerViewHeightConstraint.constant = {
      // max showing 10 rows
      let rows = (self.eligibleTokens.count + 3) / 4
      let displayTableHeight = CGFloat(min(10, rows)) * 44.0
      let maxHeight = UIScreen.main.bounds.size.height - 200.0
      return min(displayTableHeight + 110.0, maxHeight)
    }()

    self.eligibleTokensTableView.delegate = self
    self.eligibleTokensTableView.dataSource = self
    self.eligibleTokensTableView.reloadData()

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapOutSideToDismiss(_:)))
    self.view.addGestureRecognizer(tapGesture)
    self.view.isUserInteractionEnabled = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  @objc func tapOutSideToDismiss(_ sender: UITapGestureRecognizer) {
    let location = sender.location(in: self.view)
    if location.x < self.containerView.frame.minX
      || location.x > self.containerView.frame.maxX
      || location.y < self.containerView.frame.minY
      || location.y > self.containerView.frame.maxY {
      self.dismiss(animated: true, completion: nil)
    }
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension KNEligibleTokensViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  }
}

extension KNEligibleTokensViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return (self.eligibleTokens.count + 3) / 4
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: tokensTableViewCellID, for: indexPath) as! KNEligibleTokensTableViewCell
    let data = Array(self.eligibleTokens[indexPath.row * 4..<min(indexPath.row * 4 + 4, self.eligibleTokens.count)])
    cell.updateCell(with: data)
    return cell
  }
}
