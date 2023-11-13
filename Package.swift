// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ToolsOfWorship",
  products: [
    .executable(name: "ToW-Server", targets: ["Server"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-format.git", branch: ("release/5.9")),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.3"),
    .package(url: "https://github.com/hummingbird-project/hummingbird-core.git", from: "1.4.0"),
    .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "1.9.0"),
    .package(url: "https://github.com/hummingbird-project/hummingbird-mustache.git", from: "1.0.0"),
    .package(url: "https://github.com/hummingbird-project/hummingbird-auth.git", from: "1.2.0"),
    .package(url: "https://github.com/vapor/jwt-kit.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/postgres-nio.git", from: "1.18.1"),
  ],
  targets: [
    .executableTarget(
      name: "Server",
      dependencies: [
        .byName(name: "App"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .target(
      name: "App",
      dependencies: [
        .product(name: "Hummingbird", package: "hummingbird"),
        .product(name: "HummingbirdFoundation", package: "hummingbird"),
        .product(name: "HummingbirdHTTP2", package: "hummingbird-core"),
        .product(name: "HummingbirdMustache", package: "hummingbird-mustache"),
        .product(name: "HummingbirdAuth", package: "hummingbird-auth"),
        .product(name: "JWTKit", package: "jwt-kit"),
        .product(name: "PostgresNIO", package: "postgres-nio"),
      ],
      swiftSettings: [
        // Enable better optimizations when building in Release configuration. Despite the use of
        // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
        // builds. See <https://github.com/swift-server/guides#building-for-production> for details.
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
      ]
    ),
  ]
)
