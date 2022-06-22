//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent

struct CreateUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("User")
            .id()
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("User").delete()
    }
}

struct AddUsername: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("User")
            .field("username", .string)
            .update()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("User").delete()
    }
}
