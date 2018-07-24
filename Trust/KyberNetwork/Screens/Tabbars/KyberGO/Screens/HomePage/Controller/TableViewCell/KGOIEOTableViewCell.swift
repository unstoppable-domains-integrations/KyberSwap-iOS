// Copyright SIX DAY LLC. All rights reserved.

import UIKit
import Moya
import Alamofire

protocol KGOIEOTableViewCellDelegate: class {
  func ieoTableViewCellBuyButtonPressed(for object: IEOObject, sender: KGOIEOTableViewCell)
  func ieoTableViewCellShouldUpdateType(for object: IEOObject, sender: KGOIEOTableViewCell)
}

struct KGOIEOTableViewCellModel {
  let bonusDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-ddThh:mm"
    return formatter
  }()

  fileprivate let object: IEOObject
  fileprivate let isHalted: Bool

  init(object: IEOObject, isHalted: Bool) {
    self.object = object
    self.isHalted = isHalted
  }

  var highlightText: String? {
    // check sold out
    if self.object.type != .active { return "" }
    if self.object.isSoldOut { return " Sold Out ".toBeLocalised() }
    if self.isHalted { return nil }
    // check bonus
    if let bonus = self.object.getAmountBonus { return " Bonus \(bonus)% " }
    return nil
  }

  var highlightTextBackgroundColor: UIColor {
    // check sold out
    if self.object.isSoldOut { return UIColor.Kyber.orange }
    if self.isHalted { return UIColor.Kyber.darkBlue }
    // check bonus
    if self.object.getAmountBonus != nil { return UIColor.Kyber.green }
    return UIColor.white
  }

  var buyButtonTitle: String {
    if self.object.isSoldOut { return "Sold Out" }
    if self.isHalted { return "Halted" }
    return self.object.type == .active ? "Buy" : ""
  }

  var isBuyButtonEnabled: Bool {
    if self.object.isSoldOut { return false }
    if self.isHalted { return false }
    return self.object.type == .active
  }

  var buyButtonBackgroundColor: UIColor {
    if self.object.isSoldOut { return UIColor.Kyber.orange }
    if self.isHalted { return UIColor.Kyber.darkBlue }
    return UIColor.Kyber.green
  }

  var displayedName: String { return object.name }
  var displayedTime: String { return  previewTime() }
  var iconURL: String { return object.icon }
  var progress: Float { return object.progress }
  var raisedAmountText: String { return object.raisedText }
  var raisedAmountPercentText: String { return object.raisedPercent }

  fileprivate func previewTime() -> String {
    func displayDynamicTime(for time: TimeInterval) -> String {
      let timeInt = Int(floor(time))
      let timeDay: Int = 60 * 60 * 24
      let timeHour: Int = 60 * 60
      let timeMin: Int = 60
      let day = timeInt / timeDay
      let hour = (timeInt % timeDay) / timeHour
      let min = (timeInt % timeHour) / timeMin
      let sec = timeInt % timeMin
      return "\(day)d \(hour)h \(min)m \(sec)s"
    }
    let staticDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd-MMM-yyyy HH:mm"
      return formatter
    }()
    switch object.type {
    case .past:
      return "End at: \(staticDateFormatter.string(from: object.endDate))"
    case .active:
      return "End In: \(displayDynamicTime(for: object.endDate.timeIntervalSince(Date())))"
    case .upcoming:
      return "Start In: \(displayDynamicTime(for: object.startDate.timeIntervalSince(Date())))"
    }
  }
}

class KGOIEOTableViewCell: UITableViewCell {

  @IBOutlet weak var ieoHighlightLabel: UILabel!

  @IBOutlet weak var tokenIconImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var raisedAmountLabel: UILabel!
  @IBOutlet weak var raisedPercentLabel: UILabel!
  @IBOutlet weak var buyButton: UIButton!

  weak var delegate: KGOIEOTableViewCellDelegate?
  fileprivate var model: KGOIEOTableViewCellModel?

  fileprivate var countdownTimer: Timer?
  fileprivate var stateTimer: Timer?

  deinit {
    self.countdownTimer?.invalidate()
    self.stateTimer?.invalidate()
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    self.tokenIconImageView.image = nil
    self.tokenIconImageView.rounded(
      color: UIColor.Kyber.green,
      width: 2,
      radius: self.tokenIconImageView.frame.width / 2.0
    )

    self.nameLabel.text = ""
    self.timeLabel.text = ""

    self.progressView.progress = 0.0
    self.progressView.transform = self.progressView.transform.scaledBy(x: 1, y: 4.0)

    self.raisedAmountLabel.text = "0.0"
    self.raisedPercentLabel.text = "0.00 %"

    self.ieoHighlightLabel.rounded(color: UIColor.white, width: 1.0, radius: 4.0)
    self.ieoHighlightLabel.text = ""
    self.buyButton.rounded(radius: 4.0)
  }

  func updateView(with model: KGOIEOTableViewCellModel) {
    let placeholderImg: UIImage? = {
      if let curModel = self.model, curModel.object.id == model.object.id {
        return self.tokenIconImageView.image
      }
      return nil
    }()
    self.model = model
    self.tokenIconImageView.setImage(with: model.iconURL, placeholder: placeholderImg)

    self.ieoHighlightLabel.text = model.highlightText
    self.ieoHighlightLabel.backgroundColor = model.highlightTextBackgroundColor

    self.nameLabel.text = model.displayedName
    self.timeLabel.text = model.displayedTime
    self.progressView.progress = model.progress
    self.raisedAmountLabel.text = model.raisedAmountText
    self.raisedPercentLabel.text = model.raisedAmountPercentText

    if self.buyButton.currentTitle != model.buyButtonTitle {
      self.buyButton.setTitle(model.buyButtonTitle, for: .normal)
    }
    self.buyButton.isHidden = model.object.type != .active
    self.buyButton.isEnabled = model.isBuyButtonEnabled
    self.buyButton.backgroundColor = model.buyButtonBackgroundColor

    self.stateTimer?.invalidate()
    self.countdownTimer?.invalidate()
    if model.object.type == .past { return }
    if model.object.type == .active {
      self.stateTimer = Timer.scheduledTimer(withTimeInterval: model.object.endDate.timeIntervalSince(Date()), repeats: false, block: { [weak self] _ in
        guard let `self` = self, let object = self.model?.object else { return }
        self.delegate?.ieoTableViewCellShouldUpdateType(for: object, sender: self)
      })
    } else if model.object.type == .upcoming {
      self.stateTimer = Timer.scheduledTimer(withTimeInterval: model.object.startDate.timeIntervalSince(Date()), repeats: false, block: { [weak self] _ in
        guard let `self` = self, let object = self.model?.object else { return }
        self.delegate?.ieoTableViewCellShouldUpdateType(for: object, sender: self)
      })
    }
    self.countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
      self?.timeLabel.text = self?.model?.displayedTime
      self?.ieoHighlightLabel.text = self?.model?.highlightText
      self?.ieoHighlightLabel.backgroundColor = self?.model?.highlightTextBackgroundColor
    })
    self.layoutIfNeeded()
  }

  @IBAction func buyButtonPressed(_ sender: Any) {
    if let object = self.model?.object {
      self.delegate?.ieoTableViewCellBuyButtonPressed(for: object, sender: self)
    }
  }
}
