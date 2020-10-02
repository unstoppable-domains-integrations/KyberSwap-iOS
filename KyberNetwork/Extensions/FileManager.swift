// Copyright SIX DAY LLC. All rights reserved.

import Foundation

extension FileManager {
  static func sharedContainerURL() -> URL {
    return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.kyber.contents"
    )!
  }
}
