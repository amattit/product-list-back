//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent
import Vapor

final class User: BaseEntity, Model, Authenticatable, Content {
    static var schema = "User"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    @Siblings(through: UserProductList.self, from: \.$user, to: \.$productList)
    var productList: [ProductList]
    
    @Children(for: \.$user)
    var device: [Device]
    
    @Field(key: "username")
    var username: String?
    
    init() {}
    
    init(id: UUID? = nil) {
        self.id = id
    }
}



extension User {
    static func createToken(fo userId: UUID) -> Token {
      let calendar = Calendar(identifier: .gregorian)
      let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
      return Token(userId: userId,
        token: [UInt8].random(count: 16).base64, expiresAt: expiryDate)
    }
}

