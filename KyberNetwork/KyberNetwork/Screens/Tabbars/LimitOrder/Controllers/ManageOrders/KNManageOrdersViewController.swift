// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNManageOrdersViewController: KNBaseViewController {

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var filterTextLabel: UILabel!
  @IBOutlet weak var oneDayButton: UIButton!
  @IBOutlet weak var oneWeekButton: UIButton!
  @IBOutlet weak var oneMonthButton: UIButton!
  @IBOutlet weak var threeMonthButton: UIButton!

  @IBOutlet weak var separatorView: UIView!

  @IBOutlet weak var pairButton: UIButton!
  @IBOutlet weak var dateButton: UIButton!
  @IBOutlet weak var statusButton: UIButton!

  @IBOutlet weak var orderCollectionView: UICollectionView!
  @IBOutlet weak var bottomPaddingOrderCollectionViewConstraint: NSLayoutConstraint!

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  fileprivate func setupUI() {


    self.bottomPaddingOrderCollectionViewConstraint.constant = self.bottomPaddingSafeArea()
  }

  @IBAction func backButtonPressed(_ sender: Any) {
  }

  @IBAction func oneDayButtonPressed(_ sender: Any) {
  }

  @IBAction func oneWeekButtonPressed(_ sender: Any) {
  }

  @IBAction func oneMonthButtonPressed(_ sender: Any) {
  }

  @IBAction func threeMonthButtonPressed(_ sender: Any) {
  }

  @IBAction func pairButtonPressed(_ sender: Any) {
  }

  @IBAction func dateButtonPressed(_ sender: Any) {
  }

  @IBAction func statusButtonPressed(_ sender: Any) {
  }
}
