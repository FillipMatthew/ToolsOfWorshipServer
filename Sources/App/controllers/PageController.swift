import Hummingbird
import HummingbirdMustache

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

struct PageController {
    func getPage(request: HBRequest) throws -> HTML {
		let pageName = request.parameters.get("pageName") ?? "index"
		return HTML(html: request.mustache.render(HTMLContent(content: request.mustache.render((), withTemplate: "pages/\(pageName)")!), withTemplate: "main")!)
	}
}