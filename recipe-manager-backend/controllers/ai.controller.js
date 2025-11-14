const recipeGeneratorService = require('../services/ai/recipeGenerator.service');
const imageRecognitionService = require('../services/ai/imageRecognition.service');
const logger = require('../utils/logger');

exports.generateRecipes = async (req, res) => {
  try {
    const { ingredients, preferences = {} } = req.body;
    const userId = req.user?._id;

    logger.info(`Recipe generation request from user: ${userId}`);

    const recipes = await recipeGeneratorService.generateAndSaveRecipes(
      ingredients, 
      preferences, 
      userId
    );
    
    res.json({
      success: true,
      data: recipes,
      count: recipes.length,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Recipe generation error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération des recettes',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.generateMenu = async (req, res) => {
  try {
    const { ingredients, duration, preferences = {} } = req.body;
    const userId = req.user?._id;

    logger.info(`Menu generation request from user: ${userId}`);

    const menu = await recipeGeneratorService.generateAndSaveMenu(
      ingredients, 
      duration, 
      preferences, 
      userId
    );
    
    res.json({
      success: true,
      data: menu,
      generatedAt: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Menu generation error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération du menu',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

exports.generateSmartSuggestions = async (req, res) => {
  try {
    const { ingredients, preferences = {}, duration = 'day' } = req.body;
    const user = req.user;

    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Utilisateur non authentifié'
      });
    }

    const userPreferences = user.preferences || {};
    const healthProfile = user.healthProfile || {};

    const combinedPreferences = {
      ...preferences,
      diet: preferences.diet || userPreferences.diet,
      allergies: Array.from(new Set([
        ...(preferences.allergies || []),
        ...(userPreferences.allergies || []),
        ...(healthProfile.allergies || []),
        ...(healthProfile.intolerances || []),
      ])),
      excludedIngredients: Array.from(new Set([
        ...(preferences.excludedIngredients || []),
        ...(userPreferences.excludedIngredients || []),
      ])),
      healthGoals: [
        ...(healthProfile.weightManagementGoals || []),
        ...(healthProfile.dietaryGoals || []),
      ],
      conditions: [
        ...(healthProfile.conditions || []),
        ...(healthProfile.chronicConditions || []),
      ],
      lifestylePreferences: [
        ...(healthProfile.lifestylePreferences || []),
      ],
      notes: healthProfile.notes,
    };

    logger.info(`Smart suggestions request from user: ${user._id}`);

    const menuResult = await recipeGeneratorService.generateAndSaveMenu(
      ingredients,
      duration,
      combinedPreferences,
      user._id
    );

    const menu = menuResult.menu || {};
    const shoppingList = menuResult.shoppingList || [];

    res.json({
      success: true,
      data: {
        recognizedIngredients: ingredients,
        menu,
        shoppingList,
      },
      generatedAt: new Date().toISOString(),
    });
  } catch (error) {
    logger.error('Smart suggestions generation error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération des suggestions de repas',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined,
    });
  }
};

exports.detectIngredients = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: 'Aucune image fournie'
      });
    }

    logger.info('Image ingredient detection request');

    const ingredients = await imageRecognitionService.detectIngredientsFromImage(
      req.file.buffer
    );

    res.json({
      success: true,
      data: {
        detectedIngredients: ingredients,
        count: ingredients.length,
      },
      detectedAt: new Date().toISOString()
    });
  } catch (error) {
    logger.error('Ingredient detection error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la détection des ingrédients',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};