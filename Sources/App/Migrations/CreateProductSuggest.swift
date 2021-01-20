//
//  File.swift
//  
//
//  Created by 16997598 on 19.01.2021.
//

import Fluent

struct CreateProductSuggest: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ProductSuggest.schema)
            .id()
            .field("title", .string, .required)
            .field("createdAt", .datetime, .required)
            .field("price", .double)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("category", .string)
            .field("imagePath", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(ProductSuggest.schema).delete()
    }
}
