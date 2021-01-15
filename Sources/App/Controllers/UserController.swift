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
    }
    
    private func test(req: Request) throws -> EventLoopFuture<User> {
        let user = try req.auth.require(User.self)
        return req.eventLoop.future(user)
    }
    
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
