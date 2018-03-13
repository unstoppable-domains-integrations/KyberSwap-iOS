// Copyright SIX DAY LLC. All rights reserved.

/// Uses `as` to try to convert `value` to `ToType`. If this fails, an error is thrown.
public func kn_cast<FromType, ToType>(_ value: FromType, file: String = #file, line: Int = #line, function: String = #function) throws -> ToType {
  if let value = value as? ToType {
    return value
  }

  throw CastError(actualValue: FromType.self, expectedType: ToType.self)
}
