import App
import ArgumentParser
import Dispatch
import Hummingbird

struct ToWServer: ParsableCommand, AppArguments {
  @Option(name: .shortAndLong)
  var hostname: String = "0.0.0.0"

  @Option(name: .shortAndLong)
  var port: Int = 443

  @Option(name: .shortAndLong)
  var domain: String = "localhost"

  @Option(name: .shortAndLong, help: "PEM file containing certificate chain")
  var certificateChain: String = ""

  @Option(name: .long, help: "PEM file containing private key")
  var privateKey: String = ""

  @Option(name: .shortAndLong)
  var jwtSecret = "5ADF2ABA5284D168ED012502A096A0104689E07ED22E91055E503CE190CFD2BB"

  @Option(name: .long)
  var postgresServer: String = "localhost"

  @Option(name: .long)
  var postgresPort: Int = 5432

  @Option(name: .long)
  var postgresDB: String = "ToolsOfWorship"

  @Option(name: .long)
  var postgresUser: String = "postgres"

  @Option(name: .long)
  var postgresPassword: String = "postgres"

  func run() throws {
    let dg = DispatchGroup()
    dg.enter()
    Task {
      do {
        try await self.run()
      } catch {
        print(error)
      }

      dg.leave()
    }

    dg.wait()
  }

  func run() async throws {
    let app = HBApplication(
      configuration: .init(
        address: .hostname(hostname, port: port),
        serverName: "Tools of Worship"
      )
    )

    try await app.configure(self)
    try app.start()
    await app.asyncWait()
    try app.cleanup()
  }
}

ToWServer.main()
