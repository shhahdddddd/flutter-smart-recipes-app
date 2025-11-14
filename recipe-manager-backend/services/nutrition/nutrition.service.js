const logger = require('../../utils/logger');

class NutritionService {
  calculateNutritionalInfo(ingredients) {
    try {
      logger.info('Calculating nutritional info for ingredients');
      
      // Cette méthode peut être implémentée avec une API externe ou une base de données nutritionnelle
      // Pour l'instant, nous retournons des valeurs estimées basées sur les ingrédients
      
      const baseCalories = ingredients.length * 80;
      const baseProtein = ingredients.length * 5;
      const baseCarbs = ingredients.length * 10;
      const baseFat = ingredients.length * 3;

      const nutrition = {
        calories: Math.floor(baseCalories + (Math.random() * 200)),
        protein: Math.floor(baseProtein + (Math.random() * 15)),
        carbs: Math.floor(baseCarbs + (Math.random() * 30)),
        fat: Math.floor(baseFat + (Math.random() * 10)),
      };

      logger.info('Nutritional info calculated successfully');
      return nutrition;
    } catch (error) {
      logger.error('Nutrition calculation error:', error);
      throw new Error('Erreur lors du calcul des informations nutritionnelles');
    }
  }

  generateShoppingList(recipes) {
    try {
      logger.info('Generating shopping list from recipes');
      
      const shoppingList = {};
      
      recipes.forEach(recipe => {
        recipe.ingredients.forEach(ing => {
          const key = ing.name.toLowerCase().trim();
          
          if (shoppingList[key]) {
            // Fusionner les quantités
            shoppingList[key].quantity += `, ${ing.quantity}`;
          } else {
            shoppingList[key] = {
              ingredient: ing.name,
              quantity: ing.quantity,
              unit: ing.unit || '',
              purchased: false,
            };
          }
        });
      });
      
      const result = Object.values(shoppingList);
      logger.info(`Generated shopping list with ${result.length} items`);
      
      return result;
    } catch (error) {
      logger.error('Shopping list generation error:', error);
      throw new Error('Erreur lors de la génération de la liste de courses');
    }
  }
}

module.exports = new NutritionService();