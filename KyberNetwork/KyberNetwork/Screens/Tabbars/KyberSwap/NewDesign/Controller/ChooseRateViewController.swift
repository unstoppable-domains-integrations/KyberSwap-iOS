//
//  ChooseRateViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/22/20.
//

import UIKit
import BigInt

class ChooseRateViewModel {
  var data: [JSONDictionary]
  fileprivate(set) var from: TokenData
  fileprivate(set) var to: TokenData
  init(from: TokenObject, to: TokenObject, data: [JSONDictionary]) {
    self.data = data
    self.from = from.toTokenData()
    self.to = to.toTokenData()
  }
  
  init(from: TokenData, to: TokenData, data: [JSONDictionary]) {
    self.data = data
    self.from = from
    self.to = to
  }

  var uniRateText: String {
    return rateStringFor(platform: "uniswap")
  }
  
  var kyberRateText: String {
    return rateStringFor(platform: "kyber")
  }

  fileprivate func rateStringFor(platform: String) -> String {
    let dict = self.data.first { (element) -> Bool in
      if let platformString = element["platform"] as? String {
        return platformString == platform
      } else {
        return false
      }
    }
    if let rateString = dict?["rate"] as? String, let rate = BigInt(rateString) {
      return rate.isZero ? "---" : "1\(self.from.symbol) = \(rate.displayRate(decimals: 18))\(self.to.symbol)"
    } else {
      return "---"
    }
  }
}

protocol ChooseRateViewControllerDelegate: class {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String)
}

class ChooseRateViewController: KNBaseViewController {
  @IBOutlet weak var kyberRateLabel: UILabel!
  @IBOutlet weak var uniRateLabel: UILabel!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  weak var delegate: ChooseRateViewControllerDelegate?
  let viewModel: ChooseRateViewModel
  let transitor = TransitionDelegate()

  init(viewModel: ChooseRateViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ChooseRateViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.kyberRateLabel.text = self.viewModel.kyberRateText
    self.uniRateLabel.text = self.viewModel.uniRateText
  }

  @IBAction func chooseRateButtonTapped(_ sender: UIButton) {
    if sender.tag == 0 {
      self.delegate?.chooseRateViewController(self, didSelect: "kyber")
    } else {
      self.delegate?.chooseRateViewController(self, didSelect: "uniswap")
    }
    self.dismiss(animated: true, completion: nil)
  }
  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ChooseRateViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 249
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
