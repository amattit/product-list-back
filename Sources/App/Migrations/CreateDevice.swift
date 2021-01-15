//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent

struct CreateDevice: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("Device")
            .id()
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("os", .string, .required)
            .field("uid", .string, .required)
            .field("token", .string)
            .field("userId", .uuid, .required, .references("User", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("Device").delete()
    }
}
