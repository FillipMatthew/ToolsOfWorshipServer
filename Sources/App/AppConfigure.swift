import Hummingbird
import HummingbirdFoundation
import HummingbirdHTTP2
import HummingbirdMustache

public protocol AppArguments {
	var certificateChain: String { get }
	var privateKey: String { get }
}

struct HTML: HBResponseGenerator {
    let html: String

    public func response(from request: HBRequest) throws -> HBResponse {
        let buffer = request.allocator.buffer(string: self.html)
        return .init(status: .ok, headers: ["Content-Type": "text/html"], body: .byteBuffer(buffer))
    }
}

struct HTMLContent {
	let content: String
};

extension HBApplication {
    var mustache: HBMustacheLibrary {
        get { self.extensions.get(\.mustache) }
        set { self.extensions.set(\.mustache, value: newValue) }
    }

	// configure application, add middleware, setup the encoder/decoder, add your routes
	public func configure(_ arguments: AppArguments) throws {
		if (!arguments.certificateChain.isEmpty && !arguments.privateKey.isEmpty)
		{
			// Add HTTP2 TLS Upgrade option
			try server.addHTTP2Upgrade(tlsConfiguration: self.getTLSConfig(arguments))

			router.get("/http") { request in
				return "Using http v\(request.version.major).\(request.version.minor)"
			}
		}

		
		// load mustache templates from templates folder
		mustache = try .init(directory: "templates")
		assert(mustache.getTemplate(named: "main") != nil, "Working directory nust be set to the root folder of the Tools of Worship server")

		middleware.add(HBFileMiddleware(application: self))
		router.get("/", options: .editResponse) { req in
			return HTML(html: req.mustache.render(HTMLContent(content: req.mustache.render((), withTemplate: "index")!), withTemplate: "main")!)
		}
	}

	func getTLSConfig(_ arguments: AppArguments) throws -> TLSConfiguration {
		let certificateChain = try NIOSSLCertificate.fromPEMFile(arguments.certificateChain)
		let privateKey = try NIOSSLPrivateKey(file: arguments.privateKey, format: .pem)
		return TLSConfiguration.makeServerConfiguration(
			certificateChain: certificateChain.map { .certificate($0) },
			privateKey: .privateKey(privateKey)
		)
	}
}

extension HBRequest {
    var mustache: HBMustacheLibrary { self.application.mustache }
}