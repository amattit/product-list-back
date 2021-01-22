//
//  File.swift
//  
//
//  Created by 16997598 on 21.01.2021.
//

import Fluent

struct CreateShareTokens: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ShareToken.schema)
            .id()
            .field("userId", .uuid, .required, .references(User.schema, "id"))
            .field("token", .string, .required)
            .unique(on: "token")
            .field("createdAt", .datetime, .required)
            .field("expiresAt", .datetime)
            .field("productListId", .uuid, .required, .references(ProductList.schema, "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(ShareToken.schema).delete()
    }
}

struct CreateTokens: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema)
            .id()
            .field("userId", .uuid, .required)
            .field("value", .string, .required)
            .unique(on: "value")
            .field("createdAt", .datetime, .required)
            .field("expiresAt", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(Token.schema).delete()
    }
}
