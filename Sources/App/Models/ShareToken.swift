//
//  File.swift
//  
//
//  Created by 16997598 on 21.01.2021.
//

import Fluent
import Vapor

final class ShareToken: Model {
    //2
    static let schema = "ShareToken"
    
    @ID(key: .id)
    var id: UUID?
    
    //3
    @Parent(key: "userId")
    var user: User
    
    //4
    @Field(key: "token")
    var token: String
    
    //6
    @Field(key: "expiresAt")
    var expiresAt: Date?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Parent(key: "productListId")
    var productList: ProductList
    
    init() {}
    
    init(
        id: UUID? = nil,
        userId: User.IDValue,
        token: String,
        expiresAt: Date?,
        productListId: ProductList.IDValue
    ) {
        self.id = id
        self.$user.id = userId
        self.token = token
        self.expiresAt = expiresAt
        self.$productList.id = productListId
    }
}
