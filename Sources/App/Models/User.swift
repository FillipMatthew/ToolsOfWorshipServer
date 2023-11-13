import HummingbirdAuth

struct User: Codable, HBAuthenticatable {
  let id: String
  let displayName: String

  init(id: String, displayName: String) {
    self.id = id
    self.displayName = displayName
  }
}
