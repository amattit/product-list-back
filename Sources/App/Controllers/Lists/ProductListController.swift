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
        tokenProtected.delete("list", ":id", "user", ":userId", use: deleteUser)
        tokenProtected.put("list", ":id", use: update)
        tokenProtected.get("list", use: get)
        
        tokenProtected.get("list", ":id", "share-token", use: createShareToken)
        tokenProtected.delete("list", ":id", "share-token", use: deleteShareToken)
        tokenProtected.get("list", "token", ":id", use: applyShareToken)
        tokenProtected.get("list", ":id", "settings", use: settings)
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
    
    func deleteUser(req: Request) async throws -> HTTPStatus {
        let _ = try req.auth.require(User.self)
        guard let productListId = UUID(uuidString: req.parameters.get("id") ?? "") else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор списка продуктов")
        }
        
        guard let userId = req.parameters.get("userId"), let userUid = UUID(userId) else {
            throw Abort(.badRequest, reason: "Некорректный идентификатор пользователя")
        }
        
        guard let productList = try await ProductList.query(on: req.db)
            .filter(\.$id == productListId)
            .with(\.$user)
            .first() else {
            throw Abort(.notFound, reason: "Список продуктов не найден")
        }
        
        if productList.userId != userUid, let user = try productList.user.first(where: { try $0.requireID() == userUid
        }) {
            try await productList.$user.detach(user, on: req.db)
            return .ok
        }
        return .badRequest
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
    
    func get(req: Request) async throws -> [DTO.ListRs] {
        let user = try req.auth.require(User.self)
        let lists = try await user.$productList.query(on: req.db).with(\.$products).with(\.$user).all()
        var response = [DTO.ListRs]()
        for list in lists {
            let owner = list.user.first { u in
                u.id == list.userId
            }
            response.append(
                DTO.ListRs(
                    id: try list.requireID(),
                    title: list.title,
                    count: list.products.map {$0.title}.joined(separator: ", "),
                    isOwn: try user.requireID() == list.userId ? true : false,
                    isShared: list.user.count > 1,
                    profile: DTO.Profile(
                        id: try owner!.requireID(),
                        devices: [],
                        username: owner?.username
                    )
                )
            )
        }
        return response
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
    
    func settings(req: Request) async throws -> DTO.Settings {
        let _ = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Некорректный id списка продуктов")
        }
        
        guard let list = try await ProductList
            .query(on: req.db)
            .filter(\.$id == listId)
            .with(\.$user)
            .with(\.$shareToken)
            .first() else {
            throw Abort(.notFound, reason: "Запрашиваемый список не найден")
        }
        let users = try list.user.map {
            DTO.Profile(id: try $0.requireID(), devices: [], username: $0.username)
        }
        return DTO.Settings(shareToken: list.shareToken.map(\.token), users: users)
    }
    
    /// DELETE
    /// /api/v1/list/:id/share-token
    func deleteShareToken(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let id = req.parameters.get("id"), let listId = UUID(uuidString: id) else {
            throw Abort(.badRequest)
        }
        guard let list = try await ProductList.query(on: req.db).filter(\.$id == listId).with(\.$shareToken).first() else {
            throw Abort(.notFound, reason: "Список покупок не найден")
        }
        
        guard try list.userId == user.requireID() else {
            throw Abort(.badRequest, reason: "Вы не имеете права удалять ссылку")
        }
        try await list.shareToken.delete(on: req.db)
        return .ok
    }
}

extension DTO {
    struct Settings: Content {
        let shareToken: [String]?
        let users: [Profile]
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
