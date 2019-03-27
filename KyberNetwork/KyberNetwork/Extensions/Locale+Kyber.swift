// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension Locale {
  var kyberSupportedLang: String {
    let lang = self.languageCode ?? ""
    if lang == "vi" { return lang } // Vietnamese
    if lang.starts(with: "zh") { return "cn" } // Chinese
    if lang == "ko" { return "kr" } // Korea
    return "en"
  }
}
