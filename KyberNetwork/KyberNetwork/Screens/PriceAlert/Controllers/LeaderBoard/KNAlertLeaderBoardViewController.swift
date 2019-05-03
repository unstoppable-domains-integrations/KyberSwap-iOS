// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNAlertLeaderBoardViewControllerDelegate: class {
  func alertLeaderBoardViewControllerShouldBack()
  func alertLeaderBoardViewControllerOpenCampaignResult()
}

class KNAlertLeaderBoardViewController: KNBaseViewController {

  let kLeaderBoardCellID: String = "kLeaderBoardCellID"

  @IBOutlet weak var headerContainerView: UIView!
  @IBOutlet weak var navTitleLabel: UILabel!

  @IBOutlet weak var campaignHeaderTopPaddingConstraints: NSLayoutConstraint!
  @IBOutlet weak var campaignContainerView: UIView!
  @IBOutlet weak var campaignTextLabel: UILabel!
  @IBOutlet weak var campaignHeaderView: UIView!
  @IBOutlet weak var campaignNameLabel: UILabel!
  @IBOutlet weak var startTimeLabel: UILabel!
  @IBOutlet weak var endTimeLabel: UILabel!
  @IBOutlet weak var rewardCurrencyLabel: UILabel!
  @IBOutlet weak var campaignDescLabel: UILabel!
  @IBOutlet weak var campaignActionButton: UIButton!
  @IBOutlet var campaignPaddingConstraints: [NSLayoutConstraint]!
  @IBOutlet var campaignDetailsTopBottomPaddings: [NSLayoutConstraint]!
  @IBOutlet weak var separatorView: UIView!
  @IBOutlet weak var separatorHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var eligibleTokensButton: UIButton!
  @IBOutlet weak var eligibleTokensButtonHeightConstraint: NSLayoutConstraint!

  @IBOutlet var latestCampaignTopBottomPaddings: [NSLayoutConstraint]!
  @IBOutlet weak var latestCampaignPaddingConstraints: NSLayoutConstraint!
  @IBOutlet weak var latestCampaignTitleLabel: UILabel!
  @IBOutlet weak var latestCampaignEndedTextLabel: UILabel!
  @IBOutlet weak var seeTheWinnersButton: UIButton!
  @IBOutlet weak var seeTheWinnersButtonHeight: NSLayoutConstraint!

  @IBOutlet weak var alertsHeaderViewTopPadding: NSLayoutConstraint!
  @IBOutlet weak var alertsTextLabel: UILabel!
  @IBOutlet weak var leadersCollectionView: UICollectionView!
  @IBOutlet weak var noDataLabel: UILabel!

  fileprivate var leaderBoardData: [JSONDictionary] = []
  fileprivate var campaignDetails: JSONDictionary?
  fileprivate var latestCampaignTitle: String?
  fileprivate var campaignDetailsExpanded: Bool = true

  fileprivate let isShowingResult: Bool

  weak var delegate: KNAlertLeaderBoardViewControllerDelegate?

  fileprivate var timer: Timer?

  init(isShowingResult: Bool) {
    self.isShowingResult = isShowingResult
    super.init(nibName: KNAlertLeaderBoardViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    if !self.isShowingResult {
      self.timer?.invalidate()
      self.timer = nil
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.startUpdatingLeaderBoard(isFirstTime: true)
    if !self.isShowingResult {
      self.timer?.invalidate()
      self.timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true, block: { [weak self] _ in
        self?.startUpdatingLeaderBoard()
      })
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if !self.isShowingResult {
      self.timer?.invalidate()
      self.timer = nil
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    self.headerContainerView.removeSublayer(at: 0)
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)
  }

  fileprivate func setupUI() {
    self.headerContainerView.applyGradient(with: UIColor.Kyber.headerColors)
    self.navTitleLabel.text = {
      if self.isShowingResult { return NSLocalizedString("Result", comment: "") }
      return NSLocalizedString("Alert LeaderBoard", comment: "")
    }()

    self.campaignContainerView.isHidden = true

    self.campaignTextLabel.text = NSLocalizedString("Campaign(s)", comment: "").uppercased()
    let tapCampaignHeader = UITapGestureRecognizer(target: self, action: #selector(self.campaignActionButtonPressed(_:)))
    self.campaignHeaderView.addGestureRecognizer(tapCampaignHeader)
    self.campaignHeaderView.isUserInteractionEnabled = true

    let cellNib = UINib(nibName: KNLeaderBoardCollectionViewCell.className, bundle: nil)
    self.leadersCollectionView.register(cellNib, forCellWithReuseIdentifier: kLeaderBoardCellID)
    self.leadersCollectionView.delegate = self
    self.leadersCollectionView.dataSource = self
    self.leadersCollectionView.isHidden = true
    self.noDataLabel.text = NSLocalizedString("No data to show right now", comment: "")
    self.noDataLabel.isHidden = false
    self.alertsTextLabel.text = NSLocalizedString("Alert(s)", comment: "").uppercased()
    self.separatorView.backgroundColor = .clear
    self.separatorView.dashLine(width: 1.0, color: UIColor.Kyber.dashLine)

    guard IEOUserStorage.shared.user != nil else {
      self.delegate?.alertLeaderBoardViewControllerShouldBack()
      return
    }
    self.updateCampaignDetailsWithAnimation()
  }

  fileprivate func updateCampaignDetails() {
    if self.campaignDetails == nil && self.latestCampaignTitle == nil {
      // no campaign to show
      self.hideCampaignDetails(isCurrentHidden: true, isLatestHidden: true)
      self.alertsHeaderViewTopPadding.constant = 0.0
      self.campaignHeaderTopPaddingConstraints.constant = -42.0 // its height
      self.campaignHeaderView.isHidden = true
      return
    }
    // campaign details will be shown
    self.alertsHeaderViewTopPadding.constant = 1.0
    self.campaignHeaderTopPaddingConstraints.constant = 0.0
    self.campaignHeaderView.isHidden = false
    if !self.campaignDetailsExpanded {
      self.campaignActionButton.setImage(UIImage(named: "arrow_down_gray"), for: .normal)
      self.hideCampaignDetails(
        isCurrentHidden: true,
        isLatestHidden: true
      )
      return
    }
    self.campaignActionButton.setImage(UIImage(named: "arrow_up_gray"), for: .normal)
    self.hideCampaignDetails(
      isCurrentHidden: self.campaignDetails == nil,
      isLatestHidden: self.latestCampaignTitle == nil
    )
    self.campaignContainerView.isHidden = false
  }

  fileprivate func hideCampaignDetails(isCurrentHidden: Bool, isLatestHidden: Bool) {
    if isCurrentHidden {
      self.campaignNameLabel.text = nil
      self.campaignDescLabel.text = nil
      self.rewardCurrencyLabel.text = nil
      self.startTimeLabel.text = nil
      self.endTimeLabel.text = nil
      self.campaignPaddingConstraints.forEach({ $0.constant = 0 })
      self.campaignDetailsTopBottomPaddings.forEach({ $0.constant = 0.0 })
      self.separatorView.isHidden = true
      self.separatorHeightConstraint.constant = 0.0
      self.eligibleTokensButton.setTitle(nil, for: .normal)
      self.eligibleTokensButtonHeightConstraint.constant = 0.0
    } else {
      let json = self.campaignDetails ?? [:]
      self.campaignPaddingConstraints.forEach({ $0.constant = 6.0 })
      self.campaignDetailsTopBottomPaddings.forEach({ $0.constant = 16.0 })
      self.campaignActionButton.setImage(UIImage(named: "arrow_up_gray"), for: .normal)
      self.campaignNameLabel.text = json["title"] as? String
      self.campaignDescLabel.text = json["description"] as? String ?? ""
      self.rewardCurrencyLabel.text = {
        let unit = json["reward_unit"] as? String ?? ""
        return String(format: NSLocalizedString("REWARD CURRENCY: %@", value: "REWARD CURRENCY: %@", comment: ""), unit)
      }()
      self.eligibleTokensButton.setTitle(NSLocalizedString("Eligible Tokens", comment: ""), for: .normal)
      self.eligibleTokensButtonHeightConstraint.constant = 32.0
      self.startTimeLabel.text = {
        let startTime = json["start_time"] as? String ?? ""
        if let date = DateFormatterUtil.shared.promoCodeDateFormatter.date(from: startTime) {
          let string = DateFormatterUtil.shared.leaderBoardFormatter.string(from: date)
          return String(format: NSLocalizedString("Start: %@", comment: ""), string)
        }
        return nil
      }()
      self.endTimeLabel.text = {
        let endTime = json["end_time"] as? String ?? ""
        if let date = DateFormatterUtil.shared.promoCodeDateFormatter.date(from: endTime) {
          let string = DateFormatterUtil.shared.leaderBoardFormatter.string(from: date)
          return String(format: NSLocalizedString("End: %@", comment: ""), string)
        }
        return nil
      }()
      if !isLatestHidden {
        self.separatorView.isHidden = false
        self.separatorHeightConstraint.constant = 4.0
      }
    }
    if isLatestHidden {
      self.separatorView.isHidden = true
      self.separatorHeightConstraint.constant = 0.0
      self.latestCampaignTopBottomPaddings.forEach({ $0.constant = 0.0 })
      self.latestCampaignPaddingConstraints.constant = 0.0
      self.latestCampaignTitleLabel.text = nil
      self.latestCampaignEndedTextLabel.text = nil
      self.seeTheWinnersButton.setTitle(nil, for: .normal)
      self.seeTheWinnersButtonHeight.constant = 0.0
      self.seeTheWinnersButton.isHidden = true
    } else {
      self.latestCampaignTopBottomPaddings.forEach({ $0.constant = 16.0 })
      self.latestCampaignPaddingConstraints.constant = 6.0
      self.latestCampaignTitleLabel.text = self.latestCampaignTitle
      self.latestCampaignEndedTextLabel.text = NSLocalizedString("Campaign has ended.", comment: "")
      self.seeTheWinnersButton.setTitle(
        NSLocalizedString("See the winners", comment: "").uppercased(),
        for: .normal
      )
      self.seeTheWinnersButton.isHidden = false
      self.seeTheWinnersButtonHeight.constant = 32.0
    }
    self.campaignContainerView.isHidden = isCurrentHidden && isLatestHidden
  }

  fileprivate func updateCampaignDetailsWithAnimation(duration: TimeInterval = 0.25) {
    UIView.animate(withDuration: duration) {
      self.updateCampaignDetails()
      self.view.layoutIfNeeded()
    }
  }

  fileprivate func startUpdatingLeaderBoard(isFirstTime: Bool = false) {
    guard let user = IEOUserStorage.shared.user else {
      self.delegate?.alertLeaderBoardViewControllerShouldBack()
      return
    }
    self.updateCampaignDetailsWithAnimation()
    if isFirstTime { self.displayLoading() }
    if self.isShowingResult {
      KNPriceAlertCoordinator.shared.loadLatestCampaignResultData(accessToken: user.accessToken) { [weak self] (data, error) in
        guard let `self` = self else { return }
        if isFirstTime { self.hideLoading() }
        if let error = error {
          if isDebug { print("Load list leaderboard error: \(error)") }
          let alertController = UIAlertController(
            title: NSLocalizedString("error", value: "Error", comment: ""),
            message: NSLocalizedString("Can not update leader board data right now", comment: ""),
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
    } else {
      KNPriceAlertCoordinator.shared.loadLeaderBoardData(accessToken: user.accessToken) { [weak self] (data, error) in
        guard let `self` = self else { return }
        if isFirstTime { self.hideLoading() }
        if let error = error {
          if isDebug { print("Load list leaderboard error: \(error)") }
          let alertController = UIAlertController(
            title: NSLocalizedString("error", value: "Error", comment: ""),
            message: NSLocalizedString("Can not update leader board data right now", comment: ""),
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
  }

  fileprivate func updateLeaderBoardData(_ data: JSONDictionary) {
    self.campaignDetails = data["campaign_info"] as? JSONDictionary
    self.leaderBoardData = data["data"] as? [JSONDictionary] ?? []
    self.latestCampaignTitle = data["last_campaign_title"] as? String

    if !self.isShowingResult {
      if let user = IEOUserStorage.shared.user, let alert = self.leaderBoardData.first(where: { ($0["user_id"] as? Int ?? 0) == user.userID }) {
        var json = alert
        json["current_user_name"] = user.name
        self.leaderBoardData.insert(json, at: 0)
      }
    } else {
      if let user = IEOUserStorage.shared.user, let index = self.leaderBoardData.firstIndex(where: { ($0["user_id"] as? Int ?? 0) == user.userID }) {
        self.leaderBoardData[index]["current_user_name"] = user.name
      }
    }

    self.leadersCollectionView.reloadData()
    self.leadersCollectionView.isHidden = self.leaderBoardData.isEmpty
    self.noDataLabel.isHidden = !self.leaderBoardData.isEmpty
    self.view.layoutIfNeeded()
    if IEOUserStorage.shared.user != nil {
      self.updateCampaignDetailsWithAnimation()
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

  @IBAction func campaignActionButtonPressed(_ sender: Any) {
    UIView.animate(withDuration: 0.16) {
      self.campaignDetailsExpanded = !self.campaignDetailsExpanded
      self.updateCampaignDetails()
      self.view.layoutIfNeeded()
    }
  }

  @IBAction func eligibleTokensPressed(_ sender: Any) {
    guard let json = self.campaignDetails else { return }
    let data: String = {
      if let tokens = json["eligible_tokens"] as? String { return tokens }
      return KNSupportedTokenStorage.shared.supportedTokens.map({ return $0.symbol }).joined(separator: ",")
    }()
    let eligibleTokensVC = KNEligibleTokensViewController(data: data)
    eligibleTokensVC.loadViewIfNeeded()
    eligibleTokensVC.modalPresentationStyle = .overFullScreen
    eligibleTokensVC.modalTransitionStyle = .crossDissolve
    self.present(eligibleTokensVC, animated: true, completion: nil)
  }

  @IBAction func seeTheWinnerButtonPressed(_ sender: Any) {
    self.delegate?.alertLeaderBoardViewControllerOpenCampaignResult()
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
