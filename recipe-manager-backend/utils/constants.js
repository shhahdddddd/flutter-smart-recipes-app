// Constantes de l'application
module.exports = {
  // Types de régimes alimentaires
  DIET_TYPES: {
    OMNIVORE: 'omnivore',
    VEGETARIAN: 'vegetarian',
    VEGAN: 'vegan',
    PESCATARIAN: 'pescatarian',
    GLUTEN_FREE: 'gluten-free',
    DAIRY_FREE: 'dairy-free',
    NONE: 'none'
  },

  // Allergies courantes
  ALLERGIES: {
    NUTS: 'nuts',
    DAIRY: 'dairy',
    EGGS: 'eggs',
    SEAFOOD: 'seafood',
    GLUTEN: 'gluten',
    SOY: 'soy',
    NONE: 'none'
  },

  // Niveaux de difficulté
  DIFFICULTY_LEVELS: {
    EASY: 'easy',
    MEDIUM: 'medium',
    HARD: 'hard'
  },

  // Types de repas
  MEAL_TYPES: {
    BREAKFAST: 'breakfast',
    LUNCH: 'lunch',
    DINNER: 'dinner',
    SNACK: 'snack'
  },

  // Catégories de recettes
  RECIPE_CATEGORIES: {
    BREAKFAST: 'breakfast',
    LUNCH: 'lunch',
    DINNER: 'dinner',
    DESSERT: 'dessert',
    SNACK: 'snack',
    APPETIZER: 'appetizer',
    BEVERAGE: 'beverage'
  },

  // Unités de mesure
  MEASUREMENT_UNITS: {
    GRAM: 'g',
    KILOGRAM: 'kg',
    MILLILITER: 'ml',
    LITER: 'l',
    PIECE: 'pièce',
    TEASPOON: 'cuillère à café',
    TABLESPOON: 'cuillère à soupe',
    CUP: 'tasse',
    PINCH: 'pincée'
  },

  // Configuration des limites
  LIMITS: {
    MAX_INGREDIENTS_PER_RECIPE: 50,
    MAX_INSTRUCTIONS_PER_RECIPE: 30,
    MAX_RECIPES_PER_REQUEST: 10,
    MAX_IMAGE_SIZE: 5 * 1024 * 1024, // 5MB
    PASSWORD_MIN_LENGTH: 6
  },

  // Messages d'erreur standard
  ERROR_MESSAGES: {
    UNAUTHORIZED: 'Accès non autorisé',
    NOT_FOUND: 'Ressource non trouvée',
    VALIDATION_ERROR: 'Erreur de validation',
    SERVER_ERROR: 'Erreur interne du serveur',
    DUPLICATE_ENTRY: 'Entrée dupliquée'
  }
};