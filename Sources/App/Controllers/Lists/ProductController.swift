//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Vapor
import Fluent


struct ProductController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let v1 = api.grouped("v1")
        
        let tokenProtected = v1.grouped(Token.authenticator())
        tokenProtected.get("list", ":id", "product", use: get)
        tokenProtected.post("list", ":id", "product", use: create)
        tokenProtected.patch("product", ":id", use: patch)
        tokenProtected.delete("product", ":id" , use: delete)
        tokenProtected.put("product", ":id", "done", use: setDone)
        tokenProtected.put("product", ":id", "un-done", use: setUnDone)
    }
    
    func get(req: Request) throws -> EventLoopFuture<[DTO.ProductRs]> {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        
        return ProductList.find(listId, on: req.db).flatMap {
            if let list = $0 {
                return list.$user.isAttached(to: user, on: req.db).flatMap {
                    guard list.userId == user.id || $0 else {
                        return req.eventLoop.future(error: Abort(.badRequest))
                    }
                    return list.$products.query(on: req.db).all().flatMapThrowing { product in
                        return try product.map { product in
                            DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone)
                        }
                    }
                }
                
            } else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
        }
    }
    
    func create(req: Request) async throws -> DTO.ProductRs {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(DTO.CreateProductRq.self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "bad listId")
        }
        
        let product = Product()
        product.title = dto.title ?? ""
        product.count = dto.count
        product.isDone = false
        product.$user.id = try user.requireID()
        product.$productList.id = listId
        
        guard let list = try await ProductList
            .find(listId, on: req.db)
            .get() else {
            throw Abort(.badRequest, reason: "Product list not found")
        }
        
        guard try await list.$user.isAttached(to: user, on: req.db).get() else {
            throw Abort(.badRequest, reason: "User has no permissions to add product in this product list")
        }
        
        try await product.save(on: req.db).get()
        
        return DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone)
    }
    
//    func create(req: Request) throws -> EventLoopFuture<DTO.ProductRs> {
//        let user = try req.auth.require(User.self)
//        let dto = try req.content.decode(DTO.CreateProductRq.self)
//        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
//            return req.eventLoop.future(error: Abort(.badRequest))
//        }
//        let product = Product()
//        product.title = dto.title ?? ""
//        product.count = dto.count
//        product.isDone = false
//        product.$user.id = try user.requireID()
//        product.$productList.id = listId
//
//        return ProductList.find(listId, on: req.db).flatMapThrowing {
//            guard let list = $0 else {
//                throw Abort(.badRequest)
//            }
//            _ = product.save(on: req.db)
//            return  DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone)
//        }
//    }
    
    func patch(req: Request) throws -> EventLoopFuture<DTO.ProductRs> {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(DTO.CreateProductRq.self)
        guard let id = req.parameters.get("id"), let productId = UUID(uuidString: id) else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        
        return Product.find(productId, on: req.db).flatMapThrowing { product in
            guard let product = product, product.$user.id == user.id else {
                throw Abort(.badRequest)
            }
            if let title = dto.title {
                product.title = title
            }
            
            if let count = dto.count {
                product.count = count
            }
            
            _ = product.save(on: req.db)
            return DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone)
        }
    }
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let productId = UUID(uuidString: id) else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        
        return Product.find(productId, on: req.db).flatMap { product in
            guard let product = product, product.$user.id == user.id else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            
            return product.delete(on: req.db).map {
                HTTPStatus.ok
            }
        }
    }
    
    func setDone(req: Request) async throws -> DTO.ProductRs {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let productId = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Не указан id продукта в параметрах запроса")
        }
        
        guard let product = try await Product.find(productId, on: req.db) else {
            throw Abort(.notFound, reason: "Продукт с id \(id) не найден")
        }
        
        let productList = try await product.$productList.get(on: req.db)
        
        let users = try await productList.$user.get(on: req.db)
        
        guard product.$user.id == user.id || users.contains(where: { $0.id == user.id }) else {
            throw Abort(.forbidden, reason: "Нет прав изменять продукт")
        }
        
        product.isDone = true
        try await product.save(on: req.db)
        
        // переделать на job
        let usersToPush = try users.filter { user in
            try user.requireID() != user.requireID()
        }
        
        for user in usersToPush {
            let deviceTokens = try await user.$device.get(on: req.db).compactMap(\.pushToken)
            for token in deviceTokens {
                try await req.apns.send(
                    .init(title: "Купил", subtitle: product.title),
                    to: token
                ).get()
            }
        }
        
        return DTO.ProductRs(id: productId, title: product.title, count: product.count, isDone: product.isDone)
    }
    
//    func setDone(req: Request) throws -> EventLoopFuture<DTO.ProductRs> {
//        let user = try req.auth.require(User.self)
//        guard let id = req.parameters.get("id"), let productId = UUID(uuidString: id) else {
//            return req.eventLoop.future(error: Abort(.badRequest))
//        }
//        
//        // MARK: FIXME участники списка продуктов могут отмечать продукты купленными
//        return Product.find(productId, on: req.db).flatMap { product in
//            
//            guard let product = product else {
//                return req.eventLoop.future(error: Abort(.badRequest))
//            }
//            return product.$productList.get(on: req.db).map { productList in
//                productList.$user.get(on: req.db).map { users -> EventLoopFuture<DTO.ProductRs> in
//                    guard product.$user.id == user.id || users.contains(where: {$0.id == user.id}) else {
//                        return req.eventLoop.future(error: Abort(.forbidden))
//                    }
//                    product.isDone = true
//                    _ = product.save(on: req.db)
//                    return req.eventLoop.future(DTO.ProductRs(id: productId, title: product.title, count: product.count, isDone: product.isDone))
//                }
//                .flatMap { $0 }
//            }.flatMap { $0 }
//        }
//    }
    
    func setUnDone(req: Request) throws -> EventLoopFuture<DTO.ProductRs> {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let productId = UUID(uuidString: id) else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        
        // MARK: FIXME участники списка продуктов могут отмечать продукты купленными
        return Product.find(productId, on: req.db).flatMap { product in
            
            guard let product = product else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            return product.$productList.get(on: req.db).map { productList in
                productList.$user.get(on: req.db).map { users -> EventLoopFuture<DTO.ProductRs> in
                    guard product.$user.id == user.id || users.contains(where: {$0.id == user.id}) else {
                        return req.eventLoop.future(error: Abort(.forbidden))
                    }
                    product.isDone = false
                    _ = product.save(on: req.db)
                    return req.eventLoop.future(DTO.ProductRs(id: productId, title: product.title, count: product.count, isDone: product.isDone))
                }
                .flatMap { $0 }
            }.flatMap { $0 }
        }
    }
}
