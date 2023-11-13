import Hummingbird
import JWTKit
import PostgresNIO

struct UserController {
  let domain: String
  let jwtSigners: JWTSigners
  let kid: JWKIdentifier

  /// Add routes for user controller
  func addRoutes(
    to group: HBRouterGroup, jwtAuthenticator: JWTAuthenticator,
    postgresConnection: PostgresConnection
  ) {
    // group.put(options: .editResponse, use: self.create)
    group.group("login").add(middleware: BasicAuthenticator(postgresConnection: postgresConnection))
      .post(use: login)
    group.add(middleware: jwtAuthenticator).get("/", use: getUser)
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
