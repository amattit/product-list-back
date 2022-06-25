//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let v1 = api.grouped("v1")
        
        v1.post("registration", use: auth)
        
        let tokenProtected = v1.grouped(Token.authenticator())
        tokenProtected.get("me", use: test)
        tokenProtected.put("token", use: updatePushToken)
        tokenProtected.post("me", use: setUsername)
    }
    
    /// Обновить токен для пуша
    private func updatePushToken(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        let content = try req.content.decode(DTO.UpdatePushTokenRq.self)
        
        return user.$device.get(on: req.db).flatMap { devices in
            if let device = devices
                .filter({
                    $0.os == content.os
                        && $0.uid == content.uid
                }).first {
                device.pushToken = content.pushToken
                _ = device.save(on: req.db)
                return req.eventLoop.future(HTTPStatus.ok)
            } else {
                return req.eventLoop.future(HTTPStatus.custom(code: 403, reasonPhrase: "Device not found"))
            }
        }
    }
    
    /// Вернуть свой профиль
    private func test(req: Request) async throws -> DTO.Profile {
        let user = try req.auth.require(User.self)
        
        let devices = try await user.$device
            .get(on: req.db)
            .get()
            .map {
                DTO.Device(
                    uid: $0.uid,
                    pushToken: $0.pushToken,
                    os: $0.os)
            }
        
        return DTO.Profile(
            id: try user.requireID(),
            devices: devices,
            username: user.username
        )
    }
    
    /// Регистрация или авторизация
    private func auth(req: Request) throws -> EventLoopFuture<DTO.AuthRs> {
        let device = try req.content.decode(DTO.AuthRq.self)
        let user = User()
        var token: Token!
        
        return checkIfUserExists(device, req: req)
            .flatMap {
                if $0 == nil {
                    return user.save(on: req.db).flatMap {
                        token = User.createToken(fo: user.id!)
                        let _ = Device(id: nil, os: device.os, uid: device.uid, token: device.pushToken, userId: try! user.requireID())
                            .save(on: req.db)
                        return token.save(on: req.db)
                    }
                } else {
                    token = User.createToken(fo: ($0?.$user.id)!)
                    return token.save(on: req.db)
                }
            }.flatMapThrowing {
                DTO.AuthRs(token: token.value)
            }
    }
    
    private func setUsername(req: Request) async throws -> DTO.Profile {
        let user = try req.auth.require(User.self)
        let content = try req.content.decode(DTO.SetUsernameRq.self)
        
        user.username = content.username
        try await user.save(on: req.db).get()
        let devices = try await user.$device
            .get(on: req.db)
            .get()
            .map {
                DTO.Device(
                    uid: $0.uid,
                    pushToken: $0.pushToken,
                    os: $0.os)
            }
        
        return DTO.Profile(id: try user.requireID(), devices: devices, username: user.username)
    }
    
    private func checkIfUserExists(
        _ device: DTO.AuthRq,
        req: Request
    ) -> EventLoopFuture<Device?> {
        Device.query(on: req.db)
            .filter(\.$os == device.os)
            .filter(\.$uid == device.uid)
            .first()
            .map { $0 }
    }
}
