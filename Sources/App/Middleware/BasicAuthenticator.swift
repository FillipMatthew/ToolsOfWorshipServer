import Hummingbird
import HummingbirdAuth
import PostgresNIO

struct BasicAuthenticator: HBAsyncAuthenticator {
  let postgresConnection: PostgresConnection

  init(postgresConnection: PostgresConnection) {
    self.postgresConnection = postgresConnection
  }

  func authenticate(request: HBRequest) async throws -> User? {
    guard let basic = request.authBasic else { return nil }

    let userConnection = try await postgresConnection.query(
      "SELECT userId, signInType, accountId, authDetails FROM UserConnections WHERE signInType=\(SignInType.localUser.rawValue) AND accountId=\(basic.username)",
      logger: request.logger
    )

    for try await (userId, _, _, authDetails) in userConnection.decode(
      (String, Int, String, String).self)
    {
      guard Bcrypt.verify(basic.password, hash: authDetails) else { return nil }

      let user = try await postgresConnection.query(
        "SELECT displayName FROM Users WHERE id=\(userId)", logger: request.logger
      )

      for try await (displayName) in user.decode((String).self) {
        return User(id: userId, displayName: displayName)
      }
    }

    return nil
  }
}
