//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent

struct CreateProduct: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("Product")
            .id()
            .field("title", .string, .required)
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("count", .double)
            .field("measureUnit", .string)
            .field("isDone", .bool)
            .field("userId", .uuid, .required, .references("User", "id"))
            .field("productListId", .uuid, .required, .references("ProductList", "id"))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("Product").delete()
    }
}
