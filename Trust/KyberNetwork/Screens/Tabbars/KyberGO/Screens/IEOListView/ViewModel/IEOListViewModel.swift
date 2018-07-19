// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class IEOListViewModel {

  var objects: [IEOObject] = []
  var curObject: IEOObject
  var title: String

  var isHalted: [String: Bool] = [:]

  init(
    objects: [IEOObject],
    curObject: IEOObject,
    title: String,
    isHalted: [String: Bool]
    ) {
    self.objects = objects
    self.curObject = curObject
    self.title = title
    self.isHalted = isHalted
  }
}
