enum SignInType: Int {
  case none = 0
  case localUser = 1
  case googleAuth = 2
}

struct UserConnection: Codable {
  let userId: String
  let signInType: Int
  let accountId: String
  let authDetails: String

  init(userId: String, signInType: SignInType, accountId: String, authDetails: String) {
    self.userId = userId
    self.signInType = signInType.rawValue
    self.accountId = accountId
    self.authDetails = authDetails
  }
}
