//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent

struct CreateProductList: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("ProductList")
            .id()
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("title", .string, .required)
            .field("userId", .uuid, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("ProductList").delete()
    }
}
