// Copyright SIX DAY LLC. All rights reserved.

import UIKit

class KGOHomePageViewModel {
  var ieoObjects: [IEOObject] = []
  fileprivate(set) var activeObjects: [IEOObject] = []
  fileprivate(set) var pastObjects: [IEOObject] = []
  fileprivate(set) var upcomingObjects: [IEOObject] = []
//  fileprivate var dataSet: [[IEOObject]] = []
//  fileprivate var titles: [String] = []

  fileprivate(set) var isHalted: [String: Bool] = [:]

  fileprivate(set) var displayType: IEOObjectType = .active

  fileprivate(set) var displayObjects: [IEOObject] = []

  init(objects: [IEOObject]) {
    self.updateObjects(objects)
    objects.forEach({ self.isHalted[$0.contract] = $0.halted })
  }

  var isTokenSalesListHidden: Bool { return self.displayObjects.isEmpty }
  var isEmptyStateHidden: Bool { return !self.displayObjects.isEmpty }

  var numberRows: Int { return self.displayObjects.count }
  func displayObject(at row: Int) -> IEOObject? {
    if row >= self.numberRows { return nil }
    return self.displayObjects[row]
  }

  func updateObjects(_ objects: [IEOObject]) {
    self.ieoObjects = objects
    self.pastObjects = objects.filter({ $0.type == .past })
    self.activeObjects = objects.filter({ $0.type == .active }).sorted(by: { return $0.endDate < $1.endDate })
    self.upcomingObjects = objects.filter({ $0.type == .upcoming }).sorted(by: { return $0.startDate < $1.startDate })
    self.updateDisplayObjects()
  }

  func updateDisplayType(_ type: IEOObjectType) {
    self.displayType = type
    self.updateDisplayObjects()
  }

  fileprivate func updateDisplayObjects() {
    switch self.displayType {
    case .active:
      self.displayObjects = self.activeObjects
    case .upcoming:
      self.displayObjects = self.upcomingObjects
    case .past:
      self.displayObjects = self.pastObjects
    }
  }

  func previewTime(for object: IEOObject) -> String {
    func displayDynamicTime(for time: TimeInterval) -> String {
      let timeInt = Int(floor(time))
      let timeDay: Int = 60 * 60 * 24
      let timeHour: Int = 60 * 60
      let timeMin: Int = 60
      let day = timeInt / timeDay
      let hour = (timeInt % timeDay) / timeHour
      let min = (timeInt % timeHour) / timeMin
      let sec = timeInt % timeMin
      return "\(day)d \(hour)h \(min)m \(sec)s"
    }

    let staticDateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "dd-MMM-yyyy hh:mm"
      return formatter
    }()
    switch object.type {
    case .past:
      return "End at: \(staticDateFormatter.string(from: object.endDate))"
    case .active:
      return "End In: \(displayDynamicTime(for: object.endDate.timeIntervalSince(Date())))"
    case .upcoming:
      return "Start In: \(displayDynamicTime(for: object.startDate.timeIntervalSince(Date())))"
    }
  }

  func isHalted(for object: IEOObject) -> Bool {
    return self.isHalted[object.contract] ?? object.halted
  }

  func updateIsHalted(_ halted: Bool, object: IEOObject) {
    self.isHalted[object.contract] = halted
  }
}
