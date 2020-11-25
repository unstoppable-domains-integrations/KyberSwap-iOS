//
//  InputPopUpViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/24/20.
//

import UIKit
import IQKeyboardManager

class InputPopUpViewModel {
  let mainTitle: String
  let description: String
  let doneButtonTitle: String
  var completeHandle: ((String) -> ())?

  init(mainTitle: String, description: String, doneButtonTitle: String, completeHandle:((String) -> ())?) {
    self.mainTitle = mainTitle
    self.description = description
    self.doneButtonTitle = doneButtonTitle
    self.completeHandle = completeHandle
  }
  
}

class InputPopUpViewController: KNBaseViewController {
  @IBOutlet weak var mainTitleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var inputTextField: UITextField!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  let transitor = TransitionDelegate()
  let viewModel: InputPopUpViewModel
  
  init(viewModel: InputPopUpViewModel) {
    self.viewModel = viewModel
    super.init(nibName: InputPopUpViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.inputTextField.inputAccessoryView = UIView()
    self.inputTextField.rounded(radius: 8)
    IQKeyboardManager.shared().keyboardDistanceFromTextField = 100
    
    
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.inputTextField.becomeFirstResponder()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    IQKeyboardManager.shared().keyboardDistanceFromTextField = 10
  }

  @IBAction func doneButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true) {
      if let handle = self.viewModel.completeHandle {
        handle(self.inputTextField.text ?? "")
      }
    }
  }
}

extension InputPopUpViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 218
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
