// Copyright SIX DAY LLC. All rights reserved.

import UIKit

extension UIFont {
  enum Kyber {
    static func black(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-Black", size: size)! }
      return UIFont(name: "Montserrat-BlackItalic", size: size)!
    }

    static func bold(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-Bold", size: size)! }
      return UIFont(name: "Montserrat-BoldItalic", size: size)!
    }

    static func extraBold(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-ExtraBold", size: size)! }
      return UIFont(name: "Montserrat-ExtraBoldItalic", size: size)!
    }

    static func extraLight(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-ExtraLight", size: size)! }
      return UIFont(name: "Montserrat-ExtraLightItalic", size: size)!
    }

    static func light(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-Light", size: size)! }
      return UIFont(name: "Montserrat-LightItalic", size: size)!
    }

    static func italic(with size: CGFloat) -> UIFont {
      return UIFont(name: "Montserrat-Italic", size: size)!
    }

    static func medium(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-Medium", size: size)! }
      return UIFont(name: "Montserrat-MediumItalic", size: size)!
    }

    static func regular(with size: CGFloat) -> UIFont {
      return UIFont(name: "Montserrat-Regular", size: size)!
    }

    static func semiBold(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-SemiBold", size: size)! }
      return UIFont(name: "Montserrat-SemiBoldItalic", size: size)!
    }

    static func thin(with size: CGFloat, italic: Bool = false) -> UIFont {
      if !italic { return UIFont(name: "Montserrat-Thin", size: size)! }
      return UIFont(name: "Montserrat-ThinItalic", size: size)!
    }
  }
}
