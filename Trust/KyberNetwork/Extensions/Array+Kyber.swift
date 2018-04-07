// Copyright SIX DAY LLC. All rights reserved.

extension Array where Element: Equatable {
  var unique: [Element] {
    var uniqueValues = [Element]()
    forEach { element in
      if !uniqueValues.contains(element) {
        uniqueValues.append(element)
      }
    }
    return uniqueValues
  }
}

extension Array where Element: Hashable {
  var unique: [Element] {
    return Array(Set(self))
  }
}
