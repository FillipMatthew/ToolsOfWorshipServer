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
  }
}
