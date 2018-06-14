// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class IEOListViewModel {

  var objects: [IEOObject] = []
  var curObject: IEOObject
  var title: String

  init(
    objects: [IEOObject],
    curObject: IEOObject,
    title: String
    ) {
    self.objects = objects
    self.curObject = curObject
    self.title = title
  }

}
