//
//  File.swift
//  
//
//  Created by MikhailSeregin on 28.06.2022.
//

import Foundation
import Queues
import Vapor
import Fluent
//AuthTokenRemoveJob

struct RemoveTokenPayload: Codable {
    let savedTokenId: UUID
}

struct AuthTokenRemoveJob: AsyncJob {
    typealias Payload = RemoveTokenPayload
    func dequeue(_ context: QueueContext, _ payload: RemoveTokenPayload) async throws {
        guard let token = try await Token.find(payload.savedTokenId, on: context.application.db) else {
            throw Abort(.notFound)
        }
        
        try await Token.query(on: context.application.db)
            .filter(\.$user.$id == token.$user.id)
            .filter(\.$id != token.requireID())
            .all()
            .delete(on: context.application.db)
    }
    
    func error(_ context: QueueContext, _ error: Error, _ payload: RemoveTokenPayload) async throws {
        context.application.logger.error(Logger.Message(stringLiteral: error.localizedDescription))
    }
}
