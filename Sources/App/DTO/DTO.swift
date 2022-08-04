//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Vapor

struct DTO {
    struct UpsertListRq: Content {
        let id: UUID?
        let title: String
    }
    
    struct ListRs: Content {
        let id: UUID
        let title: String
        let count: String
        var isOwn: Bool?
        var isShared: Bool?
        var profile: Profile?
    }
    
    struct CreateProductRq: Content {
        let title: String?
        let count: String?
        let measureUnit: String?
        let color: String?
    }
    
    struct ProductRs: Content {
        let id: UUID
        let title: String
        let count: String?
        let isDone: Bool
        let color: String?
    }
    
    struct AuthRq: Content {
        let uid: String
        let pushToken: String?
        let os: String
    }
    
    struct AuthRs: Content {
        let token: String
    }
    
    struct UpdatePushTokenRq: Content {
        let uid: String
        let pushToken: String?
        let os: String
    }
    
    struct Profile: Content {
        let id: UUID
        let devices: [Device]
        let username: String?
    }
    
    struct SetUsernameRq: Content {
        let username: String
    }
    
    struct Device: Content {
        let uid: String
        let pushToken: String?
        let os: String
    }
}

// Рецепты
extension DTO {
    struct CreateCategoryRq: Content {
        /// Название категории
        let title: String
        /// Ссылка на картинку
        let imagePath: String?
    }
    struct CategoryRs: Content {
        /// Идентификатор категории
        let id: UUID
        /// Название категории
        let title: String
        /// Ссылка на картинку
        let imagePath: String?
        /// Количество рецептов в категории
        let count: String
    }
    
    struct CreateRecipeRq: Content {
        /// Название рецепта
        let title: String
        /// Описание рецепта
        let summary: String?
        /// Способ приготовления
        let steps: String?
        ///Ссылка на картинку
        let imagePath: String?
        
        let products: [CreateRecipeProductRq]
        
        struct CreateRecipeProductRq: Content {
            /// Название продукта
            let title: String
            /// Количество продукта
            let count: String?
        }
    }
    
    struct RecipeRs: Content {
        /// Идентификатор рецепта
        let id: UUID
        /// Название рецепта
        let title: String
        /// Описание рецепта
        let summary: String?
        /// Способ приготовления
        let steps: String?
        ///Ссылка на картинку
        let imagePath: String?
        
        let products: [RecipeProductRs]?
        
        init(recipe: Recipe, products: [RecipeProduct]? = nil) throws {
            id = try recipe.requireID()
            title = recipe.title
            summary = recipe.summary
            steps = recipe.steps
            imagePath = recipe.imagePath
            self.products = try products?.compactMap {
                DTO.RecipeProductRs(
                    id: try $0.requireID(),
                    title: $0.title,
                    count: $0.count
                )
            }
        }
    }
    
    struct RecipeProductRs: Content {
        /// Идентификатор продукта
        let id: UUID
        /// Название продукта
        let title: String
        /// Количество продукта
        let count: String?
    }
}

extension DTO {
    struct CreateSuggestRq: Content {
        let category: String
        let color: String
        /// список продуктов через запятую
        let products: String
    }
}
