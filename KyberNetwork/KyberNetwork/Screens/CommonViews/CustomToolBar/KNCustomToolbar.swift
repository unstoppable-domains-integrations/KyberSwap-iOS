// Copyright SIX DAY LLC. All rights reserved.

import UIKit

protocol KNCustomToolbarDelegate: class {
  func customToolbarLeftButtonPressed(_ toolbar: KNCustomToolbar)
  func customToolbarRightButtonPressed(_ toolbar: KNCustomToolbar)
}

class KNCustomToolbar: UIToolbar {

  weak var customDelegate: KNCustomToolbarDelegate?

  init(
    leftBtnTitle: String,
    rightBtnTitle: String,
    barTintColor: UIColor = UIColor.Kyber.enygold,
    tintColor: UIColor = .white,
    delegate: KNCustomToolbarDelegate?
    ) {
    super.init(frame: CGRect.zero)
    self.barStyle = .default
    self.isTranslucent = true
    self.barTintColor = barTintColor
    self.tintColor = tintColor
    self.customDelegate = delegate

    let leftBtn = UIBarButtonItem(
      title: leftBtnTitle,
      style: .plain,
      target: self,
      action: #selector(self.leftButtonPressed(_:))
    )
    let spaceBtn = UIBarButtonItem(
      barButtonSystemItem: .flexibleSpace,
      target: nil,
      action: nil
    )
    let rightBtn = UIBarButtonItem(
      title: rightBtnTitle,
      style: .plain,
      target: self,
      action: #selector(self.rightButtonPressed(_:))
    )
    self.setItems([leftBtn, spaceBtn, rightBtn], animated: false)
    self.isUserInteractionEnabled = true
    self.sizeToFit()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func leftButtonPressed(_ sender: Any) {
    self.customDelegate?.customToolbarLeftButtonPressed(self)
  }

  @objc func rightButtonPressed(_ sender: Any) {
    self.customDelegate?.customToolbarRightButtonPressed(self)
  }
}
