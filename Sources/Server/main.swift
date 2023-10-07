import App
import ArgumentParser
import Hummingbird

struct ToWServer: ParsableCommand, AppArguments {
	@Option(name: .shortAndLong)
	var hostname: String = "0.0.0.0"

	@Option(name: .shortAndLong)
	var port: Int = 443

	@Option(name: .shortAndLong, help: "PEM file containing certificate chain")
	var certificateChain: String = ""

	@Option(name: .long, help: "PEM file containing private key")
	var privateKey: String = ""

	func run() throws {
		let app = HBApplication(
			configuration: .init(
				address: .hostname(hostname, port: port),
				serverName: "Tools of Worship"
			)
		)

		try app.configure(self)
		try app.start()
		app.wait()
	}
}

ToWServer.main()