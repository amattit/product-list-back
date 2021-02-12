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
        
        tokenProtected.get("list", ":id", "share-token", use: createShareToken)
        tokenProtected.get("list", "token", ":id", use: applyShareToken)
    }
    
    func create(req: Request) throws -> EventLoopFuture<DTO.ListRs> {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(DTO.UpsertListRq.self)
        let item  = ProductList()
        item.title = dto.title
        item.userId = try user.requireID()
        return item.save(on: req.db).flatMapThrowing {
            _ = item.$user.attach(user, on: req.db)
            return DTO.ListRs(id: try item.requireID(), title: item.title, count: "0/0")
        }
    }
    
    func delete(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        guard let productListId = UUID(uuidString: req.parameters.get("id") ?? "") else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        return ProductList.find(productListId, on: req.db).flatMap {
            guard let list = $0 else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            
            if list.userId != user.id {
                return list.$user.isAttached(to: user, on: req.db).flatMap { isAttached in
                    if isAttached {
                        return list.delete(on: req.db).map {
                            HTTPStatus.ok
                        }
                    } else {
                        return req.eventLoop.future(error: Abort(.badRequest))
                    }
                }
            } else {
                return UserProductList.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .filter(\.$productList.$id == productListId).all()
                    .flatMap {
                        _ = list.delete(on: req.db)
                        return $0.map { $0.delete(on: req.db)}.flatten(on: req.eventLoop).transform(to: HTTPStatus.ok)
                    }
            }
            // MARK: Fix me Если удаляет владелец, то удалить все связи и удалить запись. Иначего удалить только связь
            
        }
    }
    
    func update(req: Request) throws -> EventLoopFuture<DTO.ListRs> {
        let user = try req.auth.require(User.self)
        let dto = try req.content.decode(DTO.UpsertListRq.self)
        guard let listId = req.parameters.get("id") else {
            return req.eventLoop.future(error: Abort(.badRequest))
        }
        
        return ProductList.find(UUID(uuidString: listId), on: req.db).flatMap {
            guard let list = $0, list.userId == user.id else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            list.title = dto.title
            return list.save(on: req.db).flatMap {
                return Product.query(on: req.db).count().flatMap { total in
                    return Product.query(on: req.db).filter(\.$isDone == true).count().flatMapThrowing { done in
                        DTO.ListRs(id: try list.requireID(), title: list.title, count: "\(done)/\(total)")
                    }
                }
            }
        }
    }
    
    func get(req: Request) throws -> EventLoopFuture<[DTO.ListRs]> {
        let user = try req.auth.require(User.self)
        return user.$productList.query(on: req.db).all().flatMap {
            return $0.map { list in
                list.$products.query(on: req.db).count().flatMap { total in
                    list.$products.query(on: req.db).filter(\.$isDone == true).count().flatMapThrowing { done in
                        DTO.ListRs(id: try list.requireID(), title: list.title, count: "\(done)/\(total)")
                    }
                }
            }.flatten(on: req.eventLoop)
        }
    }
    
    /// GET
    /// /api/v1/list/:id/share-token
    func createShareToken(req: Request) throws -> EventLoopFuture<DTO.ShareTokenRs> {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            throw Abort(.badRequest)
        }
        return ProductList.find(listId, on: req.db).flatMapThrowing {
            if let list = $0 {
                guard try user.requireID() == list.userId else {
                    throw Abort(.badRequest)
                }
                
                let shareToken = ShareToken.createToken(for: try user.requireID(), productListId: try list.requireID())
                let _ = shareToken.save(on: req.db)
                return DTO.ShareTokenRs(token: shareToken.token, expireAt: shareToken.expiresAt ?? Date())
            } else {
                throw Abort(.badRequest)
            }
        }
    }
    
    /// GET
    /// /api/v1/list/token/:token
    func applyShareToken(req: Request) throws -> EventLoopFuture<DTO.ListRs> {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }
        var list: ProductList!
        
        return ShareToken.query(on: req.db).filter(\.$token == id).first().flatMap {
            guard let shareToken = $0 else {
                return req.eventLoop.future(error: Abort(.badRequest))
            }
            return shareToken.$productList.get(on: req.db).map {
                list = $0
            }
        }.flatMapThrowing {
            _ = list.$user.attach(user, on: req.db)
            return DTO.ListRs(id: try list.requireID(), title: list.title, count: "0/0")
        }
    }
}

extension DTO {
    struct ShareTokenRs: Content {
        let token: String
        let expireAt: Date
    }
    struct ApplyShareTokenRq: Content {
        let token: String
    }
}


extension ShareToken {
    static func createToken(for userId: UUID, productListId: UUID) -> ShareToken {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .day, value: 1, to: Date())
        return ShareToken(userId: userId, token: UUID().uuidString, expiresAt: expiryDate, productListId: productListId)
    }
}
