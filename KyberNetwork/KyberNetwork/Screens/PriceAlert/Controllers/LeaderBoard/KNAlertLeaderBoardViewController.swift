// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNAlertLeaderBoardViewControllerDelegate: class {
  func alertLeaderBoardViewControllerShouldBack()
}

class KNAlertLeaderBoardViewController: KNBaseViewController {

  let kLeaderBoardCellID: String = "kLeaderBoardCellID"

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var userInfoContainerView: UIView!
  @IBOutlet weak var currentUserDataContainerView: UIView!
  @IBOutlet weak var userRankLabel: UILabel!
  @IBOutlet weak var userNameLabel: UILabel!
  @IBOutlet weak var userContactMethodLabel: UILabel!

  @IBOutlet weak var pairTextLabel: UILabel!
  @IBOutlet weak var pairLabel: UILabel!
  @IBOutlet weak var entryTextLabel: UILabel!
  @IBOutlet weak var entryLabel: UILabel!
  @IBOutlet weak var targetTextLabel: UILabel!
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var swingsTextLabel: UILabel!
  @IBOutlet weak var swingsLabel: UILabel!

  @IBOutlet weak var topPaddingCollectionViewConstraint: NSLayoutConstraint!
  @IBOutlet weak var leadersCollectionView: UICollectionView!
  @IBOutlet weak var noDataLabel: UILabel!

  fileprivate var leaderBoardData: [JSONDictionary] = []

  weak var delegate: KNAlertLeaderBoardViewControllerDelegate?

  fileprivate var timer: Timer?

  deinit {
    self.timer?.invalidate()
    self.timer = nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.startUpdatingLeaderBoard(isFirstTime: true)
    self.timer?.invalidate()
    self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] _ in
      self?.startUpdatingLeaderBoard()
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.timer?.invalidate()
    self.timer = nil
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = "Alert LeaderBoard".toBeLocalised()

    self.topPaddingCollectionViewConstraint.constant = 0.0
    self.currentUserDataContainerView.isHidden = true

    self.pairTextLabel.text = "Pair".toBeLocalised().uppercased()
    self.entryTextLabel.text = "Entry".toBeLocalised().uppercased()
    self.targetTextLabel.text = "Target".toBeLocalised().uppercased()
    self.swingsTextLabel.text = "Swing".toBeLocalised().uppercased()

    self.userInfoContainerView.rounded(radius: 4.0)
    self.currentUserDataContainerView.rounded(radius: 5.0)
    self.userRankLabel.rounded(radius: self.userRankLabel.frame.width / 2.0)

    let cellNib = UINib(nibName: KNLeaderBoardCollectionViewCell.className, bundle: nil)
    self.leadersCollectionView.register(cellNib, forCellWithReuseIdentifier: kLeaderBoardCellID)
    self.leadersCollectionView.delegate = self
    self.leadersCollectionView.dataSource = self
    self.leadersCollectionView.isHidden = true
    self.noDataLabel.text = "No data to show right now".toBeLocalised()
    self.noDataLabel.isHidden = false

    guard let user = IEOUserStorage.shared.user else {
      self.delegate?.alertLeaderBoardViewControllerShouldBack()
      return
    }
    self.updateUIWithUser(user)
  }

  fileprivate func resetCurrentUserData() {
    UIView.animate(withDuration: 0.25) {
      self.userRankLabel.text = "X"
      self.pairLabel.text = "X"
      self.entryLabel.text = "X"
      self.targetLabel.text = "X"
      self.swingsLabel.text = "X"
      self.currentUserDataContainerView.isHidden = true
      self.topPaddingCollectionViewConstraint.constant = 0.0
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func updateUIWithUser(_ user: IEOUser) {
    self.userNameLabel.text = user.name
    self.userContactMethodLabel.text = user.contactID
    guard let data = self.leaderBoardData.first(where: {
      return ($0["user_id"] as? Int ?? 0) == user.userID
    }) else {
      self.resetCurrentUserData()
      return
    }
    self.pairLabel.text = {
      let symbol = data["symbol"] as? String ?? ""
      let base = data["base"] as? String ?? ""
      return "\(symbol)/\(base)"
    }()
    self.entryLabel.text = {
      let price = data["created_at_price"] as? Double ?? 0.0
      return NumberFormatterUtil.shared.displayAlertPrice(from: price)
    }()
    self.targetLabel.text = {
      let target = data["alert_price"] as? Double ?? 0.0
      return NumberFormatterUtil.shared.displayAlertPrice(from: target)
    }()
    self.swingsLabel.text = {
      let change = data["percent_change"] as? Double ?? 0.0
      return NumberFormatterUtil.shared.displayPercentage(from: change) + "%"
    }()
    let rank = data["rank"] as? Int ?? 0
    self.userRankLabel.text = "\(rank)"
    self.userRankLabel.textColor = rank <= 3 ? UIColor.Kyber.shamrock : UIColor.Kyber.grayChateau
    self.userInfoContainerView.backgroundColor = rank <= 3 ? UIColor.Kyber.shamrock : UIColor.Kyber.grayChateau

    UIView.animate(withDuration: 0.25) {
      self.currentUserDataContainerView.isHidden = false
      self.topPaddingCollectionViewConstraint.constant = 142.0
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func startUpdatingLeaderBoard(isFirstTime: Bool = false) {
    guard let user = IEOUserStorage.shared.user else {
      self.delegate?.alertLeaderBoardViewControllerShouldBack()
      return
    }
    self.updateUIWithUser(user)
    if isFirstTime { self.displayLoading() }
    KNPriceAlertCoordinator.shared.loadLeaderBoardData(accessToken: user.accessToken) { [weak self] (data, error) in
      guard let `self` = self else { return }
      if isFirstTime { self.hideLoading() }
      if let error = error {
        print("Load list leaderboard error: \(error)")
        let alertController = UIAlertController(
          title: NSLocalizedString("error", value: "Error", comment: ""),
          message: "Can not update leader board data right now".toBeLocalised(),
          preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: NSLocalizedString("cancel", value: "Cancel", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("try.again", value: "Try Again", comment: ""), style: .default, handler: { _ in
          self.startUpdatingLeaderBoard(isFirstTime: true)
        }))
        self.present(alertController, animated: true, completion: nil)
      } else {
        self.updateLeaderBoardData(data)
      }
    }
  }

  fileprivate func updateLeaderBoardData(_ data: [JSONDictionary]) {
    self.leaderBoardData = data
    self.leadersCollectionView.reloadData()
    self.leadersCollectionView.isHidden = data.isEmpty
    self.noDataLabel.isHidden = !data.isEmpty
    self.view.layoutIfNeeded()
    if let user = IEOUserStorage.shared.user {
      self.updateUIWithUser(user)
    } else {
      self.delegate?.alertLeaderBoardViewControllerShouldBack()
    }
  }

  @IBAction func screenEdgePanActionChanged(_ sender: UIScreenEdgePanGestureRecognizer) {
    if sender.state == .ended {
      self.delegate?.alertLeaderBoardViewControllerShouldBack()
    }
  }

  @IBAction func backButtonPressed(_ sender: Any) {
    self.delegate?.alertLeaderBoardViewControllerShouldBack()
  }
}

extension KNAlertLeaderBoardViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 8.0
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(
      width: collectionView.frame.width - 16.0,
      height: KNLeaderBoardCollectionViewCell.height
    )
  }
}
extension KNAlertLeaderBoardViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
  }
}

extension KNAlertLeaderBoardViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return self.leaderBoardData.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kLeaderBoardCellID, for: indexPath) as! KNLeaderBoardCollectionViewCell
    let data = self.leaderBoardData[indexPath.row]
    cell.updateCell(with: data, at: indexPath.row)
    return cell
  }
}
