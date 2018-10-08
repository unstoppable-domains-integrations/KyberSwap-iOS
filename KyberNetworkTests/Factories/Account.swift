// Copyright SIX DAY LLC. All rights reserved.

import Foundation
@testable import Trust
import TrustKeystore
import TrustCore

extension Account {
    static func make(
        address: Address = .make(),
        url: URL = URL(fileURLWithPath: "")
    ) -> Account {
        return Account(address: address, type: .encryptedKey, url: url)
    }
}



