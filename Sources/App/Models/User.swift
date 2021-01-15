//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent
import Vapor

final class User: BaseEntity, Model, Authenticatable {
    static var schema = "User"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    init() {}
    
    init(id: UUID? = nil) {
        self.id = id
    }
}

final class Token: Model {
  //2
  static let schema = "Token"
  
  @ID(key: "id")
  var id: UUID?
  
  //3
  @Parent(key: "userId")
  var user: User
  
  //4
  @Field(key: "value")
  var value: String
  
  //6
  @Field(key: "expiresAt")
  var expiresAt: Date?
  
  @Timestamp(key: "createdAt", on: .create)
  var createdAt: Date?
  
  init() {}
    
    init(
        id: UUID? = nil,
        userId: User.IDValue,
        token: String,
        expiresAt: Date?
    ) {
        self.id = id
        self.$user.id = userId
        self.value = token
        self.expiresAt = expiresAt
    }
}

extension User {
    func createToken() throws -> Token {
      let calendar = Calendar(identifier: .gregorian)
      let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
      return try Token(userId: requireID(),
        token: [UInt8].random(count: 16).base64, expiresAt: expiryDate)
    }
}

extension Token: ModelTokenAuthenticatable {
  static let valueKey = \Token.$value
  static let userKey = \Token.$user
  
  var isValid: Bool {
    guard let expiryDate = expiresAt else {
      return true
    }
    
    return expiryDate > Date()
  }
}

