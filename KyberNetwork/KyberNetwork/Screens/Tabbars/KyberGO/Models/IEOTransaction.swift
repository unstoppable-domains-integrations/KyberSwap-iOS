// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

enum IEOTransactionStatus: String {
  case success = "success"
  case fail = "fail"
  case lost = "lost"
  case pending = "pending"
  case unknown = ""

  var displayText: String {
    switch self {
    case .success: return "Transaction Success"
    case .fail: return "Transaction Failed"
    case .lost: return "Transaction Lost"
    case .pending: return "Transaction Pending"
    default: return "Unknown Status"
    }
  }
}

class IEOTransaction: Object {

  @objc dynamic var id: Int = -1
  @objc dynamic var userID: Int = -1
  @objc dynamic var ieoID: Int = -1
  @objc dynamic var txHash: String = ""
  @objc dynamic var status: String = ""
  @objc dynamic var createdDate: Date = Date()
  @objc dynamic var updatedDate: Date = Date()
  @objc dynamic var distributedTokensWei: Double = 0
  @objc dynamic var payedWei: Double = 0
  @objc dynamic var viewed: Bool = false
  @objc dynamic var srcAddress: String = ""
  @objc dynamic var destAddress: String = ""
  @objc dynamic var sentETH: Double = 0.0
  @objc dynamic var displayStatus: String = ""

  convenience init(dict: JSONDictionary) {
    self.init()
    self.id = dict["id"] as? Int ?? -1
    self.userID = dict["user_id"] as? Int ?? -1
    self.ieoID = dict["ieo_id"] as? Int ?? -1
    self.txHash = dict["tx_hash"] as? String ?? ""
    self.status = dict["status"] as? String ?? ""
    self.createdDate = {
      let date = dict["created_at"] as? Double ?? 0.0
      return Date(timeIntervalSince1970: date / 1000.0)
    }()
    self.updatedDate = {
      let date = dict["updated_at"] as? Double ?? 0.0
      return Date(timeIntervalSince1970: date / 1000.0)
    }()
    self.distributedTokensWei = dict["distributed_tokens_wei"] as? Double ?? 0.0
    self.payedWei = dict["payed_wei"] as? Double ?? 0.0
    self.viewed = dict["viewed"] as? Bool ?? false
    self.srcAddress = dict["src_address"] as? String ?? ""
    self.destAddress = dict["dest_address"] as? String ?? ""
    self.sentETH = dict["sent_eth"] as? Double ?? 0.0
    self.displayStatus = dict["display_status"] as? String ?? ""
  }

  override class func primaryKey() -> String? {
    return "id"
  }

  var txStatus: IEOTransactionStatus {
    return IEOTransactionStatus(rawValue: self.status) ?? .unknown
  }
}
