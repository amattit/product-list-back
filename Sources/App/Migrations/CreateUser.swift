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

struct CreateTokens: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(Token.schema)
      .field("id", .uuid, .identifier(auto: true))
      .field("userId", .uuid, .references("User", "id"))
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
