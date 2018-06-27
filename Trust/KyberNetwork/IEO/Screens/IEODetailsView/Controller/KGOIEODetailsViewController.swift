// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import BigInt

protocol KGOIEODetailsViewControllerDelegate: class {
  func ieoDetailsViewControllerDidPressBuy(for object: IEOObject, sender: KGOIEODetailsViewController)
  func ieoDetailsViewControllerDidPressWhitePaper(for object: IEOObject, sender: KGOIEODetailsViewController)
}

class KGOIEODetailsViewController: KNBaseViewController {

  @IBOutlet weak var scrollContainerView: UIScrollView!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var bannerImageView: UIImageView!
  @IBOutlet weak var iconImageView: UIImageView!

  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!

  @IBOutlet weak var endTimeLabel: UILabel!

  @IBOutlet weak var daysLabel: UILabel!
  @IBOutlet weak var hoursLabel: UILabel!
  @IBOutlet weak var minutesLabel: UILabel!
  @IBOutlet weak var secondsLabel: UILabel!

  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var raisedAmountLabel: UILabel!
  @IBOutlet weak var raisedPercentLabel: UILabel!

  @IBOutlet weak var rateLabel: UILabel!
  @IBOutlet weak var buyTokenButton: UIButton!
  @IBOutlet weak var bonusEndDateLabel: UILabel!

  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var whitePaperButton: UIButton!

  weak var delegate: KGOIEODetailsViewControllerDelegate?
  fileprivate(set) var viewModel: KGOIEODetailsViewModel
  fileprivate var countTimer: Timer?

  init(viewModel: KGOIEODetailsViewModel) {
    self.viewModel = viewModel
    super.init(nibName: KGOIEODetailsViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    self.countTimer?.invalidate()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.countTimer?.invalidate()
    self.countTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] _ in
      self?.updateDisplayTime()
      if let type = self?.viewModel.object.type, type == .past {
        self?.countTimer?.invalidate()
        return
      }
    })
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    self.countTimer?.invalidate()
  }

  fileprivate func setupUI() {
    self.scrollContainerView.delegate = self
    if self.viewModel.isFull {
      self.closeButton.isHidden = false
    } else {
      self.view.rounded(color: .lightGray, width: 0.5, radius: 5.0)
      self.closeButton.isHidden = true
    }
    self.bannerImageView.rounded(color: .lightGray, width: 0.5, radius: 0.0)
    if let url = self.viewModel.bannerURL {
      self.bannerImageView.setImage(with: url, placeholder: nil)
    }
    self.iconImageView.rounded(
      color: .lightGray,
      width: 0.5,
      radius: self.iconImageView.frame.width / 2.0
    )
    if let url = self.viewModel.iconURL {
      self.iconImageView.setImage(with: url, placeholder: nil)
    }

    self.nameLabel.text = self.viewModel.displayedName
    self.contentLabel.text = self.viewModel.displayedContent
    self.endTimeLabel.rounded(radius: 4.0)

    self.updateDisplayTime()

    self.progressView.transform = self.progressView.transform.scaledBy(x: 1, y: 5.0)
    self.progressView.rounded(radius: 2.5)
    self.buyTokenButton.rounded(radius: 4.0)
    self.buyTokenButton.titleLabel?.numberOfLines = 2
    self.buyTokenButton.titleLabel?.lineBreakMode = .byWordWrapping
    self.buyTokenButton.titleLabel?.textAlignment = .center

    self.descriptionLabel.text = self.viewModel.displayedDesc
    self.whitePaperButton.setAttributedTitle(self.viewModel.whitePaperAttributedText, for: .normal)

    self.updateDisplayRateAndBonus()
    self.updateProgess()
  }

  fileprivate func updateDisplayTime() {
    self.endTimeLabel.attributedText = self.viewModel.endDaysAttributedString
    self.daysLabel.attributedText = self.viewModel.displayedDayAttributedString
    self.hoursLabel.attributedText = self.viewModel.displayedHourAttributedString
    self.minutesLabel.attributedText = self.viewModel.displayedMinuteAttributedString
    self.secondsLabel.attributedText = self.viewModel.displayedSecondAttributedString
    self.updateProgess()
  }

  fileprivate func updateDisplayRateAndBonus() {
    self.rateLabel.text = self.viewModel.rateText
  }

  fileprivate func updateProgess() {
    self.progressView.progress = self.viewModel.displayedRaisedProgress

    self.raisedAmountLabel.text = self.viewModel.displayedRaisedAmount
    self.raisedPercentLabel.text = self.viewModel.displayedRaisedPercent

    self.buyTokenButton.isEnabled = self.viewModel.buyTokenButtonEnabled
    self.buyTokenButton.setTitle(self.viewModel.buyTokenButtonTitle, for: .normal)
    self.buyTokenButton.backgroundColor = self.viewModel.buyTokenButtonBackgroundColor

    self.bonusEndDateLabel.isHidden = self.viewModel.isBonusEndDateHidden
    if !self.bonusEndDateLabel.isHidden {
      self.bonusEndDateLabel.text = self.viewModel.bonusEndText
    }
    self.view.layoutIfNeeded()
  }

  @IBAction func buyTokenButtonPressed(_ sender: Any) {
    self.delegate?.ieoDetailsViewControllerDidPressBuy(
      for: self.viewModel.object,
      sender: self
    )
  }

  @IBAction func whitePaperButtonPressed(_ sender: Any) {
    self.delegate?.ieoDetailsViewControllerDidPressWhitePaper(
      for: self.viewModel.object,
      sender: self
    )
  }

  @IBAction func closeButtonPressed(_ sender: Any) {
    self.dismiss(animated: true, completion: nil)
  }

  func coordinatorDidUpdateProgress() {
    if let object = IEOObjectStorage.shared.getObject(primaryKey: self.viewModel.object.id) {
      self.viewModel.object = object
      self.updateProgess()
    }
  }

  func coordinatorDidUpdateRate(_ rate: BigInt, object: IEOObject) {
    if self.viewModel.object.id == object.id {
      self.viewModel.updateCurrentRate(rate)
      self.updateDisplayRateAndBonus()
    }
  }
}

extension KGOIEODetailsViewController: UIScrollViewDelegate {

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y < 0 {
    }
  }
}
