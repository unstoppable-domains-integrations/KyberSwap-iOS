//
//  TokenData.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 1/29/21.
//

import Foundation

struct TokenData: Equatable {
  let address: String
  let name: String
  let symbol: String
  let decimals: Int
  let lendingPlatforms: [LendingPlatformData]
  
  static func == (lhs: TokenData, rhs: TokenData) -> Bool {
    return lhs.address.lowercased() == rhs.address.lowercased()
  }
  
  var isETH: Bool {
    return self.symbol == "ETH"
  }
}

struct LendingPlatformData {
  let name: String
  let supplyRate: Double
  let stableBorrowRate: Double
  let variableBorrowRate: Double
  let distributionSupplyRate: Double
  let distributionBorrowRate: Double
  
  var isCompound: Bool {
    return self.name == "Compound"
  }
}
