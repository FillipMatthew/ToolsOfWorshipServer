import Hummingbird

extension HBApplication {
  func setupDatabase() async throws {
    let tables = try await postgresConnection.query(
      "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';",
      logger: logger)

    for try await (tablename) in tables.decode(String.self, context: .default) {
      if tablename == "users" {
        return
      }
    }

    try await postgresConnection.query(
      "CREATE TABLE Users (id TEXT NOT NULL PRIMARY KEY, displayName TEXT NOT NULL);",
      logger: logger)

    try await postgresConnection.query(
      "CREATE TABLE UserConnections (userId TEXT NOT NULL, signInType INTEGER, accountId TEXT, authDetails TEXT);",
      logger: logger
    )

    try await postgresConnection.query(
      "CREATE TABLE Fellowships (id TEXT NOT NULL, name TEXT NOT NULL, creator TEXT NOT NULL);",
      logger: logger
    )

    try await postgresConnection.query(
      "CREATE TABLE FellowshipMembers (fellowshipId TEXT NOT NULL, userId TEXT NOT NULL, access INTEGER);",
      logger: logger
    )

    try await postgresConnection.query(
      "CREATE TABLE FellowshipCircles (id TEXT NOT NULL, fellowshipId TEXT NOT NULL, name TEXT NOT NULL, type INTEGER);",
      logger: logger
    )

    try await postgresConnection.query(
      "CREATE TABLE CircleMembers (circleId TEXT NOT NULL, userId TEXT NOT NULL, access INTEGER);",
      logger: logger
    )

    try await postgresConnection.query(
      "CREATE TABLE Posts (id TEXT NOT NULL, authorId TEXT NOT NULL, fellowshipId TEXT, circleId TEXT, dateTime TIMESTAMPTZ, heading TEXT NOT NULL, article TEXT NOT NULL);",
      logger: logger
    )
  }
}
