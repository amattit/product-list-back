//
//  File.swift
//  
//
//  Created by MikhailSeregin on 24.06.2022.
//

import Fluent
import Vapor

/// Контроллер рецептов. Может работать без авторизации
/// Что может делать:
/// 1. Получить конкретный рецепт **[GET]/api/v1/recipe/:recipeId**
/// 2. Получить все рецепты **[GET]/api/v1/recipe без привязки к категориям**
/// 3. Получить список категорий рецептов **[GET]/api/v1/recipe/category**
/// 4. Получить все рецепты в категории **[GET]/api/v1/recipe/category/:id**
///
/// Требуется авторизация
/// 5. Добавить продукты к списку покупок **[POST]/api/v1/recipe/:recipeId**
struct RecipeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let v1 = api.grouped("v1")
        // группировка по пути /api/v1/recipe
        let recipe = v1.grouped("recipe")
        recipe.get(use: getAllRecipes)
        recipe.get(":recipeId", use: getRecipe)
        // группировка по пути /api/v1/recipe/category
        let category = recipe.grouped("category")
        category.get(use: getCategories)
        category.get(":categoryId", use: getRecipeInCategory)
        // для добавления продуктов из рецепта в список покупок
        let tokenProtected = v1.grouped(Token.authenticator())
        
        category.post(use: createCategory)
        category.post(":categoryId", use: createRecipe)
        
        let list = tokenProtected.grouped("list", ":listId", "recipe")
        list.post(use: sendRecipeToList)
    }
}
