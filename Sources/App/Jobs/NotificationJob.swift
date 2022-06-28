//
//  File.swift
//  
//
//  Created by MikhailSeregin on 28.06.2022.
//

import Foundation
import Queues
import Vapor

struct NotificationJob: AsyncJob {
    typealias Payload = NotificationMessage
    
    func dequeue(_ context: QueueContext, _ payload: NotificationMessage) async throws {
        guard let product = try await Product.find(payload.producId, on: context.application.db) else {
            throw Abort(.notFound, reason: "Продукт с id \(payload.producId) не найден")
        }
        
        let productList = try await product.$productList.get(on: context.application.db)
        
        let users = try await productList.$user.get(on: context.application.db)
        
        let usersToPush = try users.filter {
            try $0.requireID() != payload.userId
        }
        
        for user in usersToPush {
            let deviceTokens = try await user.$device.get(on: context.application.db).compactMap(\.pushToken)
            for token in deviceTokens {
                try await context.application.apns.send(
                    .init(title: payload.title, subtitle: payload.subtitle),
                    to: token
                ).get()
            }
        }
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: NotificationMessage) async throws {
        context.logger.info(Logger.Message(stringLiteral: "Ошибка при отправке сообщения \(payload.description)"))
    }
}

struct NotificationMessage: Codable {
    let title: String
    let subtitle: String
    let producId: UUID
    let userId: UUID
    var description: String {
        "title: " + title + "\nsubtitle: " + subtitle
    }
}
