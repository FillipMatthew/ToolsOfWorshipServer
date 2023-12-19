import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdFoundation
import JWTKit
import PostgresNIO

struct UserController {
  let domain: String
  let jwtSigners: JWTSigners
  let kid: JWKIdentifier
  let postgresConnection: PostgresConnection

  /// Add routes for user controller
  func addRoutes(to group: HBRouterGroup, jwtAuthenticator: JWTAuthenticator) {
    // group.put(options: .editResponse, use: self.create)
    group.group("register").post(use: register)
    group.group("login").add(middleware: BasicAuthenticator(postgresConnection: postgresConnection))
      .post(use: login)
    group.add(middleware: jwtAuthenticator).get("/", use: getUser)
  }

  func register(_ request: HBRequest) async throws -> String {
    struct UserRegistrationData: Decodable {
      var displayName: String
      var email: String
      var password: String
    }

    let registrationData = try request.decode(as: UserRegistrationData.self)

    let userConnection = try await postgresConnection.query(
      "SELECT userId, signInType, accountId, authDetails FROM UserConnections WHERE accountId = \(registrationData.email)",
      logger: request.logger
    )

    for try await (_, _, _, _) in (userConnection).decode(
      (String, Int, String, String).self)
    {
      throw HBHTTPError(.badRequest, message: "Email already used")
    }

    let userId = UUID().uuidString

    try await postgresConnection.query(
      "INSERT INTO UserConnections (userId, signInType, accountId, authDetails) VALUES (\(userId), \(SignInType.localUser.rawValue), \(registrationData.email), \(Bcrypt.hash(registrationData.password)))",
      logger: request.logger)

    try await postgresConnection.query(
      "INSERT INTO Users (id, displayName) VALUES (\(userId), \(registrationData.displayName))",
      logger: request.logger)

    return "Registered (\(registrationData.displayName))"
  }

  func login(_ request: HBRequest) async throws -> [String: String] {
    let user = try request.authRequire(User.self)

    let payload = JWTPayloadData(
      subject: .init(value: user.id),
      expiration: .init(value: Date(timeIntervalSinceNow: 12 * 60 * 60)),
      issuer: .init(value: domain),
      audience: .init(value: domain)
    )

    return try [
      "token": jwtSigners.sign(payload, kid: kid)
    ]
  }

  func getUser(_ request: HBRequest) async throws -> String {
    let user = try request.authRequire(User.self)
    return "Authenticated (\(user.displayName))"
  }
}
