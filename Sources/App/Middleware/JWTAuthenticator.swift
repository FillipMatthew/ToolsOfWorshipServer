import Foundation
import HummingbirdAuth
import JWTKit
import PostgresNIO

struct JWTPayloadData: JWTPayload, Equatable, HBAuthenticatable {
  enum CodingKeys: String, CodingKey {
    case subject = "sub"
    case expiration = "exp"
    case issuer = "iss"
    case audience = "aud"
  }

  var subject: SubjectClaim
  var expiration: ExpirationClaim
  var issuer: IssuerClaim
  var audience: AudienceClaim

  func verify(using signer: JWTSigner) throws {
    try expiration.verifyNotExpired()
  }
}

struct JWTAuthenticator: HBAsyncAuthenticator {
  let domain: String
  let postgresConnection: PostgresConnection
  let jwtSigners: JWTSigners

  init(domain: String, postgresConnection: PostgresConnection) {
    self.jwtSigners = JWTSigners()
    self.domain = domain
    self.postgresConnection = postgresConnection
  }

  init(
    _ signer: JWTSigner, kid: JWKIdentifier? = nil, domain: String,
    postgresConnection: PostgresConnection
  ) {
    self.jwtSigners = JWTSigners()
    self.jwtSigners.use(signer, kid: kid)
    self.domain = domain
    self.postgresConnection = postgresConnection
  }

  init(jwksData: ByteBuffer, domain: String, postgresConnection: PostgresConnection) throws {
    let jwks = try JSONDecoder().decode(JWKS.self, from: jwksData)
    self.jwtSigners = JWTSigners()
    try self.jwtSigners.use(jwks: jwks)
    self.domain = domain
    self.postgresConnection = postgresConnection
  }

  func useSigner(_ signer: JWTSigner, kid: JWKIdentifier? = nil) {
    self.jwtSigners.use(signer, kid: kid)
  }

  func authenticate(request: HBRequest) async throws -> User? {
    // Get JWT from bearer authorisation
    guard let jwtToken = request.authBearer?.token else { throw HBHTTPError(.unauthorized) }

    let payload: JWTPayloadData
    do {
      payload = try self.jwtSigners.verify(jwtToken, as: JWTPayloadData.self)
    } catch {
      request.logger.debug("couldn't verify token")
      throw HBHTTPError(.unauthorized)
    }

    var isForUs = false
    for val in payload.audience.value {
      // Add a better test, other services might use https://[host] for example.
      if val == domain {
        isForUs = true
        break
      }
    }

    if !isForUs {
      request.logger.debug("token not for us")
      throw HBHTTPError(.unauthorized)
    }

    if payload.issuer.value == domain {
      let user = try await postgresConnection.query(
        "SELECT displayName FROM Users WHERE id=\(payload.subject.value)", logger: request.logger
      )

      for try await (displayName) in user.decode((String).self) {
        return User(id: payload.subject.value, displayName: displayName)
      }
    } else {
      // JWT from other services trigger create new user if not already created.
    }

    throw HBHTTPError(.unauthorized)
  }
}
