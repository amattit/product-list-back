//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Vapor
import Fluent

final class UserProductList: Model {
    static let schema = "UserProductList"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "userId")
    var user: User
    
    @Parent(key: "productListId")
    var productList: ProductList
    
    init() {}
    
    init(id: UUID? = nil, user: User, productList: ProductList) throws {
        self.id = id
        self.$user.id = try user.requireID()
        self.$productList.id = try productList.requireID()
    }
}
