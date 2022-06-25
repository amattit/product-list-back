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
    
    func search(req: Request) throws -> EventLoopFuture<[ProductSuggest]> {
        let query = try req.query.decode(SearchRq.self)
        
        return ProductSuggest.query(on: req.db).filter(\ProductSuggest.$title, .custom("ilike"), "%\(query.title)%").all().map {
            return $0
        }
//        return ProductSuggest.query(on: req.db).all()
        
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
