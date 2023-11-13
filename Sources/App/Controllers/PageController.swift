import Hummingbird
import HummingbirdMustache

struct HTMLContent {
  let content: String
}

struct PageController {
  let mustache: HBMustacheLibrary
  let mainTemplate: HBMustacheTemplate

  init(mustacheLibrary: HBMustacheLibrary) {
    mustache = mustacheLibrary

    // Get the mustache templates from the library
    guard let mainTemplate = mustacheLibrary.getTemplate(named: "main")
    else {
      preconditionFailure("Failed to load mustache templates")
    }

    self.mainTemplate = mainTemplate
  }

  // Add routes for webpages
  func addRoutes(to router: HBRouterBuilder) {
    router.group()
      .get("/", use: getPage)
  }

  func getPage(request: HBRequest) throws -> HTML {
    let pageName = request.parameters.get("pageName") ?? "index"
    return HTML(
      html: mainTemplate.render(
        HTMLContent(content: mustache.render((), withTemplate: "pages/\(pageName)")!)))
  }
}
