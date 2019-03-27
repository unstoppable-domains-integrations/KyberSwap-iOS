// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KNCustomSegmentedControl: UISegmentedControl {

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    self.sendActions(for: .touchDown)
  }
}
