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
        tokenProtected.post("list", ":id", "products", use: massCreate)
        tokenProtected.patch("product", ":id", use: patch)
        tokenProtected.delete("product", ":id" , use: delete)
        tokenProtected.put("product", ":id", "done", use: setDone)
        tokenProtected.put("product", ":id", "un-done", use: setUnDone)
    }
    
    func get(req: Request) async throws -> [DTO.ProductRs] {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            throw Abort(.badRequest)
        }
        
        guard let productList = try await ProductList.find(listId, on: req.db) else {
            throw Abort(.notFound, reason: "Список с id \(id) не найден")
        }
        
        let isUserAttached = try await productList.$user.isAttached(to: user, on: req.db)
        
        guard isUserAttached else {
            throw Abort(.forbidden, reason: "У вас нету прав на чтение списка покупок")
        }
        
        return try await productList.$products
            .query(on: req.db)
            .all()
            .map { product in
                DTO.ProductRs(
                    id: try product.requireID(),
                    title: product.title,
                    count: product.count,
                    isDone: product.isDone,
                    color: product.color
                )
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
        product.color = dto.color
        
        guard let list = try await ProductList
            .find(listId, on: req.db) else {
            throw Abort(.badRequest, reason: "Product list not found")
        }
        
        guard try await list.$user.isAttached(to: user, on: req.db).get() else {
            throw Abort(.badRequest, reason: "User has no permissions to add product in this product list")
        }
        
        try await product.save(on: req.db).get()
        
        try await req.queue.dispatch(
            NotificationJob.self,
            NotificationMessage(
                title: "Купи",
                subtitle: product.title,
                producId: product.requireID(),
                userId: user.requireID()
            )
        )
        
        return DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone, color: product.color)
    }
    
    func massCreate(req: Request) async throws -> [DTO.ProductRs] {
        let user = try req.auth.require(User.self)
        let dtos = try req.content.decode([DTO.CreateProductRq].self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "bad listId")
        }
        
        let products = try dtos.map { dto -> Product in
            let product = Product()
            product.title = dto.title ?? ""
            product.count = dto.count
            product.isDone = false
            product.$user.id = try user.requireID()
            product.$productList.id = listId
            product.color = dto.color
            return product
        }
        
        guard let list = try await ProductList
            .find(listId, on: req.db)
            .get() else {
            throw Abort(.badRequest, reason: "Product list not found")
        }
        
        guard try await list.$user.isAttached(to: user, on: req.db).get() else {
            throw Abort(.badRequest, reason: "User has no permissions to add product in this product list")
        }
        
        try await products.create(on: req.db)
        
        if let productId = try? products.first?.requireID() {
            try await req.queue.dispatch(
                NotificationJob.self,
                NotificationMessage(
                    title: "Купи",
                    subtitle: products.map(\.title).joined(separator: " "),
                    producId: productId,
                    userId: user.requireID()
                )
            )
        }
        
        return try products.map { product -> DTO.ProductRs in
            DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone, color: product.color)
        }
    }
    
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
            return DTO.ProductRs(id: try product.requireID(), title: product.title, count: product.count, isDone: product.isDone, color: product.color)
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
        
        try await req.queue.dispatch(
            NotificationJob.self,
            NotificationMessage(
                title: "Купил",
                subtitle: product.title,
                producId: productId,
                userId: user.requireID()
            )
        )
        
        return DTO.ProductRs(id: productId, title: product.title, count: product.count, isDone: product.isDone, color: product.color)
    }
    
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
                    return req.eventLoop.future(DTO.ProductRs(id: productId, title: product.title, count: product.count, isDone: product.isDone, color: product.color))
                }
                .flatMap { $0 }
            }.flatMap { $0 }
        }
    }
}
