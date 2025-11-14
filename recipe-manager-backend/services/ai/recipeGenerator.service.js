const Recipe = require('../../models/Recipe');
const aiService = require('./ai.service');
const logger = require('../../utils/logger');

class RecipeGeneratorService {
  async generateAndSaveRecipes(ingredients, preferences, userId) {
    try {
      logger.info(`Generating and saving recipes for user: ${userId}`);
      
      const aiRecipes = await aiService.generateRecipes(ingredients, preferences);
      
      if (!aiRecipes.recipes || !Array.isArray(aiRecipes.recipes)) {
        throw new Error('Format de réponse IA invalide');
      }

      const savedRecipes = [];
      for (const recipeData of aiRecipes.recipes) {
        const recipe = new Recipe({
          ...recipeData,
          createdBy: userId,
          isAIGenerated: true,
        });
        
        const savedRecipe = await recipe.save();
        savedRecipes.push(savedRecipe);
      }
      
      logger.info(`Successfully saved ${savedRecipes.length} AI-generated recipes`);
      return savedRecipes;
    } catch (error) {
      logger.error('Recipe generation and save error:', error);
      throw error;
    }
  }

  async generateAndSaveMenu(ingredients, duration, preferences, userId) {
    try {
      logger.info(`Generating ${duration} menu for user: ${userId}`);
      const aiMenu = await aiService.generateMenu(ingredients, duration, preferences);
      if (!aiMenu.menu) {
        throw new Error('Format de réponse IA invalide pour le menu');
      }
      logger.info(`Successfully generated ${duration} menu`);
      return aiMenu;
    } catch (error) {
      logger.error('Menu generation error:', error);
      try {
        const wanted = (ingredients || []).filter(Boolean);
        const nameRegexes = wanted.map(i => new RegExp(String(i).trim(), 'i'));
        const filter = nameRegexes.length ? { 'ingredients.name': { $in: nameRegexes } } : {};
        const limit = duration === 'week' ? 7 : 3;
        const recipes = await Recipe.find(filter).sort({ createdAt: -1 }).limit(limit);

        const lower = arr => Array.isArray(arr) ? arr.map(x => String(x).toLowerCase()) : [];
        const excluded = new Set([ ...lower(preferences?.allergies), ...lower(preferences?.excludedIngredients) ]);
        const have = new Set(wanted.map(i => String(i).toLowerCase()));

        const meals = recipes.map((r, idx) => ({
          day: idx + 1,
          mealType: 'dinner',
          recipe: {
            title: r.title,
            ingredients: (r.ingredients || []).map(i => ({ name: i.name, quantity: i.quantity || '' })),
            instructions: (r.instructions || []).map(s => ({ step: s.step || 1, description: s.description || '' })),
            cookingTime: r.cookingTime,
            difficulty: r.difficulty,
          }
        }));

        const shoppingSet = new Set();
        recipes.forEach(r => {
          (r.ingredients || []).forEach(i => {
            const n = String(i.name || '').toLowerCase();
            if (n && !have.has(n) && !excluded.has(n)) {
              shoppingSet.add(JSON.stringify({ ingredient: i.name, quantity: i.quantity || '' }));
            }
          });
        });

        const shoppingList = Array.from(shoppingSet).map(s => JSON.parse(s));

        return {
          menu: {
            title: duration === 'week' ? 'Fallback Weekly Menu' : 'Fallback Daily Menu',
            description: 'Generated locally from your ingredients and preferences',
            duration: duration === 'week' ? 7 : 1,
            meals,
          },
          shoppingList,
        };
      } catch (fallbackError) {
        logger.error('Fallback menu generation error:', fallbackError);
        throw error;
      }
    }
  }
}

module.exports = new RecipeGeneratorService();