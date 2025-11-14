const { ai: aiConfig } = require('../config/app.config');

const validateRecipeGeneration = (req, res, next) => {
  const { ingredients, preferences = {} } = req.body;

  if (!ingredients || !Array.isArray(ingredients)) {
    return res.status(400).json({
      success: false,
      error: 'La liste d\'ingrédients est requise et doit être un tableau'
    });
  }

  if (ingredients.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'La liste d\'ingrédients ne peut pas être vide'
    });
  }

  if (ingredients.length > aiConfig.maxIngredients) {
    return res.status(400).json({
      success: false,
      error: `Trop d'ingrédients. Maximum: ${aiConfig.maxIngredients}`
    });
  }

  // Validate preferences structure
  if (preferences.diet && !['vegetarian', 'vegan', 'gluten-free', 'none'].includes(preferences.diet)) {
    return res.status(400).json({
      success: false,
      error: 'Régime alimentaire non valide'
    });
  }

  next();
};

const validateMenuGeneration = (req, res, next) => {
  const { ingredients, duration, preferences = {} } = req.body;

  if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'La liste d\'ingrédients est requise et doit être un tableau non vide'
    });
  }

  if (duration && !['day', 'week'].includes(duration)) {
    return res.status(400).json({
      success: false,
      error: 'La durée doit être "day" ou "week"'
    });
  }

  next();
};

const validateRecipe = (req, res, next) => {
  const { title, ingredients, instructions, cookingTime } = req.body;

  if (!title?.trim()) {
    return res.status(400).json({
      success: false,
      error: 'Le titre est requis'
    });
  }

  if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Au moins un ingrédient est requis'
    });
  }

  if (!instructions || !Array.isArray(instructions) || instructions.length === 0) {
    return res.status(400).json({
      success: false,
      error: 'Au moins une instruction est requise'
    });
  }

  if (!cookingTime || cookingTime < 1) {
    return res.status(400).json({
      success: false,
      error: 'Le temps de cuisson est requis et doit être positif'
    });
  }

  next();
};

module.exports = {
  validateRecipeGeneration,
  validateMenuGeneration,
  validateRecipe
};