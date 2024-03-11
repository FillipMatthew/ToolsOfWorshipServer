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
      .get("/", use: getHome)
      .get("/login", use: getLogin)
      .get("/register", use: getRegister)
  }

  func getHome(request: HBRequest) throws -> HTML {
    return HTML(
      html: mainTemplate.render(
        HTMLContent(content: mustache.render((), withTemplate: "content/index")!)))
  }

  func getLogin(request: HBRequest) throws -> HTML {
    return HTML(
      html: mainTemplate.render(
        HTMLContent(content: mustache.render((), withTemplate: "content/login")!)))
  }

  func getRegister(request: HBRequest) throws -> HTML {
    return HTML(
      html: mainTemplate.render(
        HTMLContent(content: mustache.render((), withTemplate: "content/register")!)))
  }
}
