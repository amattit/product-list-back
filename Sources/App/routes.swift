import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("index")
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
//    app.post("upload") { req -> String in
//        struct Input: Content {
//            var filename: File
//        }
//        let input = try req.content.decode(Input.self)
//
//        guard input.filename.data.readableBytes > 0 else {
//            throw Abort(.badRequest)
//        }
//        var bytes = input.filename.data
//        guard let data = bytes.readData(length: 100) else {
//            throw Abort(.badRequest)
//        }
//        let string = String(data: data, encoding: .utf8) ?? "opps"
//        return string
//        
//    }

    try app.register(collection: TodoController())
    try app.register(collection: UserController())
    try app.register(collection: ProdutListController())
    try app.register(collection: ProductController())
    try app.register(collection: AdminController())
    try app.register(collection: RecipeController())
}
