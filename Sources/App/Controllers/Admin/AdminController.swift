//
//  File.swift
//  
//
//  Created by 16997598 on 19.01.2021.
//

import Vapor
import Fluent

struct AdminController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
//        routes.post("upload", use: uploadData)
        routes.on(.POST, "upload", body: .collect(maxSize: .some(19999900000)), use: uploadData(req:))
        routes.get("api", "v1", "search", use: search)
        routes.post("api", "v1", "suggest", use: create)
    }
    
    func uploadData(req: Request) throws -> EventLoopFuture<String> {
        struct Input: Content {
            var filename: File
        }
        let input = try req.content.decode(Input.self)

        guard input.filename.data.readableBytes > 0 else {
            throw Abort(.badRequest)
        }
        var bytes = input.filename.data
        guard let data = bytes.readData(length: input.filename.data.readableBytes) else {
            throw Abort(.badRequest)
        }
        
        guard let rawData = String(data: data, encoding: .utf8) else {
            throw Abort(.badRequest)
        }
        
        var rows = rawData.split(separator: "\r\n")
        rows.remove(at: 0)
        
        return ProductSuggest.query(on: req.db).all().map { self.delete($0, req: req) }.flatMap {
            for item in rows {
                let properties = item.split(separator: ";")
                let category = String(properties[0])
                let title = String(properties[1])
                let price = Double(Int(properties[2]) ?? 0)
                let imagePath = String(properties[3])
                _ = ProductSuggest(id: nil, category: category, price: price, title: title, imagePath: imagePath).save(on: req.db)
            }
            
            let string = ProductSuggest.query(on: req.db).all().map {
                return $0.map {
                    $0.title + "\n"
                }.joined()
            }
            
            return string
        }
    }
    
    func search(req: Request) async throws -> [ProductSuggest] {
        let query = try req.query.decode(SearchRq.self)
        return try await ProductSuggest.query(on: req.db)
            .group(.or) { group in
                group.filter(\ProductSuggest.$title, .custom("ilike"), "%\(query.title)%").filter(\ProductSuggest.$category, .custom("ilike"), "%\(query.title)%")
            }
            .all()
    }
    
    func create(req: Request) async throws -> [ProductSuggest] {
        let dto = try req.content.decode(DTO.CreateSuggestRq.self)
        let products = dto.products.split(separator: ",").map {
            ProductSuggest(category: dto.category, price: 0, title: String($0), imagePath: "", color: dto.color)
        }
        
        try await products.create(on: req.db)
        
        return products
    }
    
    func delete(_ items: [ProductSuggest], req: Request) {
        _ = items.map { $0.delete(on: req.db)}
    }
}

struct SearchRq: Content {
    let title: String
}

struct Suggest: Codable {
    let category: String
    let title: String
    let price: Double
    let imagePath: String
}
