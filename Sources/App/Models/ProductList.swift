//
//  File.swift
//  
//
//  Created by 16997598 on 14.01.2021.
//

import Fluent
import Vapor

final class ProductList: BaseEntity, Model {
    static var schema = "ProductList"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "userId")
    var userId: UUID
    
    @Siblings(through: UserProductList.self, from: \.$productList, to: \.$user)
    var user: [User]
    
    @Children(for: \.$productList)
    var products: [Product]
    
}
