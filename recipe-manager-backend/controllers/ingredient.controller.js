const Ingredient = require('../models/Ingredient');
const logger = require('../utils/logger');

exports.getIngredients = async (req, res) => {
  try {
    const { category, search, page = 1, limit = 50 } = req.query;
    
    const filter = {};
    if (category) filter.category = category;
    if (search) {
      filter.name = { $regex: search, $options: 'i' };
    }

    const skip = (page - 1) * limit;
    
    const ingredients = await Ingredient.find(filter)
      .sort({ name: 1 })
      .skip(skip)
      .limit(parseInt(limit));
    
    const total = await Ingredient.countDocuments(filter);

    logger.info(`Retrieved ${ingredients.length} ingredients`);

    res.json({
      success: true,
      data: ingredients,
      count: ingredients.length,
      total,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    logger.error('Get ingredients error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des ingrédients'
    });
  }
};

exports.getIngredient = async (req, res) => {
  try {
    const ingredient = await Ingredient.findById(req.params.id);
    
    if (!ingredient) {
      return res.status(404).json({
        success: false,
        error: 'Ingrédient non trouvé'
      });
    }

    res.json({
      success: true,
      data: ingredient
    });
  } catch (error) {
    logger.error('Get ingredient error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de l\'ingrédient'
    });
  }
};

exports.createIngredient = async (req, res) => {
  try {
    const ingredient = new Ingredient(req.body);
    const savedIngredient = await ingredient.save();
    
    logger.info(`Created new ingredient: ${savedIngredient.name}`);

    res.status(201).json({
      success: true,
      data: savedIngredient,
    });
  } catch (error) {
    logger.error('Create ingredient error:', error);
    
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'Cet ingrédient existe déjà'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création de l\'ingrédient'
    });
  }
};

exports.updateIngredient = async (req, res) => {
  try {
    const ingredient = await Ingredient.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!ingredient) {
      return res.status(404).json({
        success: false,
        error: 'Ingrédient non trouvé'
      });
    }

    logger.info(`Updated ingredient: ${ingredient.name}`);

    res.json({
      success: true,
      data: ingredient,
    });
  } catch (error) {
    logger.error('Update ingredient error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour de l\'ingrédient'
    });
  }
};

exports.deleteIngredient = async (req, res) => {
  try {
    const ingredient = await Ingredient.findByIdAndDelete(req.params.id);

    if (!ingredient) {
      return res.status(404).json({
        success: false,
        error: 'Ingrédient non trouvé'
      });
    }

    logger.info(`Deleted ingredient: ${ingredient.name}`);

    res.json({
      success: true,
      message: 'Ingrédient supprimé avec succès',
    });
  } catch (error) {
    logger.error('Delete ingredient error:', error);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression de l\'ingrédient'
    });
  }
};