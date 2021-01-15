//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Vapor
import Fluent

struct ProdutListController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let v1 = api.grouped("v1")
        
        let tokenProtected = v1.grouped(Token.authenticator())
        tokenProtected.post("list", use: create)
        tokenProtected.delete("list", ":id", use: delete)
        tokenProtected.put("list", ":id", use: update)
        tokenProtected.get("list", use: get)
    }
    
    func create(req: Request) throws -> EventLoopFuture<DTO.ListRs> {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(DTO.UpsertListRq.self)
        let item  = ProductList()
        item.title = dto.title
        item.$user.id = try user.requireID()
        return item.save(on: req.db).flatMapThrowing {
            DTO.ListRs(id: try item.requireID(), title: item.title, count: 0)
        }
    }
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard let productListId = req.parameters.get("id") else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        return ProductList.find(UUID(uuidString: productListId), on: req.db).flatMap {
            guard let list = $0, list.$user.id == user.id else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            return list.delete(on: req.db).map {
                HTTPStatus.ok
            }
        }
    }
    
    func update(req: Request) throws -> EventLoopFuture<DTO.ListRs> {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(DTO.UpsertListRq.self)
        guard let listId = req.parameters.get("id") else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        
        return ProductList.find(UUID(uuidString: listId), on: req.db).flatMap {
            guard let list = $0, list.$user.id == user.id else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            list.title = dto.title
            return list.save(on: req.db).flatMap {
                return Product.query(on: req.db).count().flatMapThrowing { int in
                    DTO.ListRs(id: try list.requireID(), title: list.title, count: int)
                }
            }
        }
    }
    
    func get(req: Request) throws -> EventLoopFuture<[DTO.ListRs]> {
        let user = try req.auth.require(User.self)
        
        return user.$productList.query(on: req.db).all().flatMap {
            return $0.map { list in
                list.$products.query(on: req.db).count().flatMapThrowing {
                    return DTO.ListRs(id: try list.requireID(), title: list.title, count: $0)
                }
            }.flatten(on: req.eventLoop)
        }
    }
}
