import Hummingbird
import HummingbirdFoundation
import HummingbirdHTTP2
import HummingbirdMustache
import JWTKit
import Logging
import PostgresNIO

public protocol AppArguments {
  var domain: String { get }
  var certificateChain: String { get }
  var privateKey: String { get }
  var jwtSecret: String { get }
  var postgresServer: String { get }
  var postgresPort: Int { get }
  var postgresDB: String { get }
  var postgresUser: String { get }
  var postgresPassword: String { get }
}

extension HBApplication {
  // Configure application, add middleware, setup the encoder/decoder, add your routes
  public func configure(_ arguments: AppArguments) async throws {
    try await setupDB(arguments)
    setupJWT(arguments)

    encoder = JSONEncoder()
    decoder = JSONDecoder()

    if !arguments.certificateChain.isEmpty && !arguments.privateKey.isEmpty {
      // // Add TLS
      // try server.addTLS(tlsConfiguration: getTLSConfig(arguments)) done in HTTP2 upgrade handler

      // Add HTTP2 TLS Upgrade option
      try server.addHTTP2Upgrade(tlsConfiguration: getTLSConfig(arguments))

      router.get("/http") { request in
        return "Using http v\(request.version.major).\(request.version.minor)"
      }
    }

    // Add info logging
    middleware.add(HBLogRequestsMiddleware(.debug))

    middleware.add(
      HBCORSMiddleware(
        allowOrigin: .originBased,
        allowHeaders: ["Accept", "Authorization", "Content-Type", "Origin"],
        allowMethods: [.GET, .OPTIONS]
      ))

    // Add a file middleware
    middleware.add(HBFileMiddleware(application: self))

    // Server health check
    router.get("/health") { _ -> HTTPResponseStatus in
      return .ok
    }

    // Load mustache templates from templates folder
    let mustache: HBMustacheLibrary = try .init(directory: "templates")
    assert(
      mustache.getTemplate(named: "main") != nil,
      "Working directory must be set to the root folder of the Tools of Worship server")

    // Add page controller routes
    PageController(mustacheLibrary: mustache).addRoutes(to: router)

    UserController(
      domain: arguments.domain,
      jwtSigners: jwtAuthenticator.jwtSigners, kid: jwtLocalSignerKid
    ).addRoutes(
      to: router.group("api/user"), jwtAuthenticator: jwtAuthenticator,
      postgresConnection: postgresConnection)
  }

  public func cleanup() throws {
    try postgresConnection.close().wait()
  }

  func getTLSConfig(_ arguments: AppArguments) throws -> TLSConfiguration {
    let certificateChain = try NIOSSLCertificate.fromPEMFile(arguments.certificateChain)
    let privateKey = try NIOSSLPrivateKey(file: arguments.privateKey, format: .pem)
    return TLSConfiguration.makeServerConfiguration(
      certificateChain: certificateChain.map { .certificate($0) },
      privateKey: .privateKey(privateKey)
    )
  }

  func setupDB(_ arguments: AppArguments) async throws {
    let logger = Logger(label: "postgres-logger")

    postgresConnection = try await PostgresConnection.connect(
      configuration: .init(
        host: arguments.postgresServer,
        port: arguments.postgresPort,
        username: arguments.postgresUser,
        password: arguments.postgresPassword,
        database: arguments.postgresDB,
        tls: .disable),
      id: 1,
      logger: logger
    )
  }

  func setupJWT(_ arguments: AppArguments) {
    jwtAuthenticator = JWTAuthenticator(
      domain: arguments.domain, postgresConnection: postgresConnection)
    jwtLocalSignerKid = JWKIdentifier("local_signer")
    jwtAuthenticator.useSigner(.hs256(key: arguments.jwtSecret), kid: jwtLocalSignerKid)
  }
}

extension HBApplication {
  var jwtLocalSignerKid: JWKIdentifier {
    get {
      self.extensions.get(\.jwtLocalSignerKid, error: "JWT local signer kid not initialised!")
    }
    set {
      self.extensions.set(\.jwtLocalSignerKid, value: newValue) { kid in
      }
    }
  }

  var jwtAuthenticator: JWTAuthenticator {
    get {
      self.extensions.get(\.jwtAuthenticator, error: "JWT Authenticator not initialised!")
    }
    set {
      self.extensions.set(\.jwtAuthenticator, value: newValue) { authenticator in
      }
    }
  }

  var postgresConnection: PostgresConnection {
    get {
      self.extensions.get(\.postgresConnection, error: "PostgreSQL connection not initialised!")
    }
    set {
      self.extensions.set(\.postgresConnection, value: newValue) { connection in
        try connection.close().wait()
      }
    }
  }
}
