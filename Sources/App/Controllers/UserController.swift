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
        let userRoute = routes.grouped("/api/v1")
        userRoute.post("registration", use: auth)
    }
    
    fileprivate func auth(req: Request) throws -> EventLoopFuture<DTO.AuthRs> {
        let device = try req.content.decode(DTO.AuthRq.self)
        let user = User()
        var token: Token!
        
        return checkIfUserExists(device, req: req)
            .flatMap {
                if $0 == nil {
                    return user.save(on: req.db).flatMap {
                        // MARK: FixMe
                        token = try! user.createToken()
                        return token.save(on: req.db)
                    }
                } else {
                    // MARK: FixMe
                    token = try! $0?.user.createToken()
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
