//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent

struct CreateUserProductList: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(UserProductList.schema)
            .id()
            .field("userId", .uuid, .required, .references(User.schema, "id"))
            .field("productListId", .uuid, .required, .references(ProductList.schema, "id"))
            .unique(on: "userId", "productListId")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(UserProductList.schema).delete()
    }
}
