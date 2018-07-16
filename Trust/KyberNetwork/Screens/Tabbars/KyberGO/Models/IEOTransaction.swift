// Copyright SIX DAY LLC. All rights reserved.

import RealmSwift

enum IEOTransactionStatus: String {
  case success = "success"
  case fail = "fail"
  case lost = "lost"
  case pending = "pending"
  case unknown = ""
}

class IEOTransaction: Object {

  @objc dynamic var id: Int = -1
  @objc dynamic var userID: Int = -1
  @objc dynamic var ieoID: Int = -1
  @objc dynamic var txHash: String = ""
  @objc dynamic var status: String = ""
  @objc dynamic var createdDate: Date = Date()
  @objc dynamic var updatedDate: Date = Date()
  @objc dynamic var distributedTokensWei: Int32 = 0
  @objc dynamic var payedWei: Int32 = 0
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
      return Date(timeIntervalSince1970: date)
    }()
    self.updatedDate = {
      let date = dict["updated_at"] as? Double ?? 0.0
      return Date(timeIntervalSince1970: date)
    }()
    self.distributedTokensWei = dict["distributed_tokens_wei"] as? Int32 ?? 0
    self.payedWei = dict["payed_wei"] as? Int32 ?? 0
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
